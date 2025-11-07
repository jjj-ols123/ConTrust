Future<void> _processPCABDocument(XFile image) async {
  setState(() => _isLoading = true);
  
  try {
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Create document record
    final docResponse = await Supabase.instance.client
        .from('documents')
        .insert({
          'original_filename': image.name,
          'file_size': bytes.length,
          'file_type': 'image/jpeg',
        })
        .select()
        .single();

    // Process with PCAB validation
    final response = await Supabase.instance.client.functions.invoke(
      'textract-processor',
      body: {
        'documentId': docResponse['id'],
        'imageBase64': base64Image,
        'documentType': 'pcab', // Specify PCAB validation
      },
    );

    if (response.error != null) {
      throw Exception('Processing failed: ${response.error}');
    }

    final result = response.data;
    
    // Show PCAB-specific results
    if (result['verified'] == true) {
      _showPCABSuccess(result);
    } else {
      _showPCABFailure(result);
    }

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

void _showPCABSuccess(Map<String, dynamic> result) {
  final findings = result['pcabFindings'] as Map<String, dynamic>;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.verified, color: Colors.green),
          SizedBox(width: 8),
          Text('PCAB Certificate Verified'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PCAB Score: ${result['pcabScore']}/100'),
            Text('Confidence: ${result['confidence']}%'),
            SizedBox(height: 12),
            
            if (findings['licenseNumbers']?.isNotEmpty == true) ...[
              Text('License Numbers:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...findings['licenseNumbers'].map<Widget>((num) => Text('• $num')),
              SizedBox(height: 8),
            ],
            
            if (findings['categories']?.isNotEmpty == true) ...[
              Text('Categories:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...findings['categories'].map<Widget>((cat) => Text('• $cat')),
              SizedBox(height: 8),
            ],
            
            if (findings['dates']?.isNotEmpty == true) ...[
              Text('Dates Found:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...findings['dates'].map<Widget>((date) => Text('• $date')),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}

void _showPCABFailure(Map<String, dynamic> result) {
  final reasons = List<String>.from(result['reasons'] ?? []);
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 8),
          Text('PCAB Verification Failed'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PCAB Score: ${result['pcabScore'] ?? 0}/100'),
          SizedBox(height: 8),
          Text('Issues found:'),
          SizedBox(height: 8),
          ...reasons.map((reason) => Text('• $reason')),
          SizedBox(height: 12),
          Text('Please ensure you\'re uploading a valid PCAB certificate.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Try Again'),
        ),
      ],
    ),
  );
}

__________________________________________________________________________________________________

-- edge function --

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { TextractClient, AnalyzeDocumentCommand } from "https://esm.sh/@aws-sdk/client-textract@3.0.0";
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};
// PCAB validation patterns
const PCAB_VALIDATION_RULES = {
  // Required text patterns that must be present
  requiredTexts: [
    'PCAB',
    'Philippine Contractors Accreditation Board',
    'Certificate',
    'License',
    'Registration'
  ],
  // PCAB license number patterns
  licensePatterns: [
    /PCAB[- ]?\d{4,}/i,
    /License[- ]?No[.:][- ]?\d+/i,
    /Registration[- ]?No[.:][- ]?\d+/i,
    /\b\d{4,8}\b/ // 4-8 digit numbers (license numbers)
  ],
  // Category patterns (A, B, C, D, etc.)
  categoryPatterns: [
    /Category[- ]?[A-Z]/i,
    /Class[- ]?[A-Z]/i,
    /\bCategory\s*[A-Z]\b/i // Category A
  ],
  // Date patterns
  datePatterns: [
    /\d{1,2}[\/\-]\d{1,2}[\/\-]\d{4}/,
    /\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2}/,
    /(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2},?\s+\d{4}/i,
    /\d{1,2}\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}/i // 1 January 2024
  ],
  // Company/contractor name indicators
  companyIndicators: [
    'Corporation',
    'Corp',
    'Inc',
    'Company',
    'Co',
    'Construction',
    'Contractor',
    'Builders',
    'Engineering'
  ]
};
function validatePCABDocument(extractedText) {
  const text = extractedText.toUpperCase();
  const findings = {
    hasPCABText: false,
    hasLicenseNumber: false,
    hasCategory: false,
    hasValidDates: false,
    hasCompanyName: false,
    licenseNumbers: [],
    categories: [],
    dates: [],
    companyIndicators: []
  };
  const reasons = [];
  let score = 0;
  // 1. Check for PCAB-related text (25 points)
  const pcabTextFound = PCAB_VALIDATION_RULES.requiredTexts.some((reqText)=>text.includes(reqText.toUpperCase()));
  if (pcabTextFound) {
    findings.hasPCABText = true;
    score += 25;
  } else {
    reasons.push('No PCAB-related text found');
  }
  // 2. Check for license numbers (30 points)
  for (const pattern of PCAB_VALIDATION_RULES.licensePatterns){
    const matches = extractedText.match(pattern);
    if (matches) {
      findings.hasLicenseNumber = true;
      findings.licenseNumbers.push(...matches);
      score += 30;
      break;
    }
  }
  if (!findings.hasLicenseNumber) {
    reasons.push('No valid license number found');
  }
  // 3. Check for category/class (20 points)
  for (const pattern of PCAB_VALIDATION_RULES.categoryPatterns){
    const matches = extractedText.match(pattern);
    if (matches) {
      findings.hasCategory = true;
      findings.categories.push(...matches);
      score += 20;
      break;
    }
  }
  if (!findings.hasCategory) {
    reasons.push('No contractor category found');
  }
  // 4. Check for valid dates (15 points)
  for (const pattern of PCAB_VALIDATION_RULES.datePatterns){
    const matches = extractedText.match(pattern);
    if (matches) {
      findings.hasValidDates = true;
      findings.dates.push(...matches);
      score += 15;
      break;
    }
  }
  if (!findings.hasValidDates) {
    reasons.push('No valid dates found');
  }
  // 5. Check for company indicators (10 points)
  const companyFound = PCAB_VALIDATION_RULES.companyIndicators.some((indicator)=>text.includes(indicator.toUpperCase()));
  if (companyFound) {
    findings.hasCompanyName = true;
    findings.companyIndicators = PCAB_VALIDATION_RULES.companyIndicators.filter((indicator)=>text.includes(indicator.toUpperCase()));
    score += 10;
  } else {
    reasons.push('No company/contractor indicators found');
  }
  // Determine if valid (minimum 70% score)
  const isValid = score >= 70;
  return {
    isValid,
    score,
    findings,
    reasons: isValid ? [] : reasons
  };
}
serve(async (req)=>{
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders
    });
  }
  try {
    const supabaseClient = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_ANON_KEY') ?? '', {
      global: {
        headers: {
          Authorization: req.headers.get('Authorization')
        }
      }
    });
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) {
      throw new Error('Unauthorized');
    }
    const { documentId, imageBase64, documentType = 'pcab' } = await req.json();
    // Initialize Textract
    const textractClient = new TextractClient({
      region: Deno.env.get('AWS_REGION') || 'us-east-1',
      credentials: {
        accessKeyId: Deno.env.get('AWS_ACCESS_KEY'),
        secretAccessKey: Deno.env.get('AWS_SECRET_KEY')
      }
    });
    // Update status to processing
    await supabaseClient.from('documents').update({
      processing_status: 'processing'
    }).eq('id', documentId);
    // Process with Textract - use AnalyzeDocument for better form extraction
    const imageBytes = Uint8Array.from(atob(imageBase64), (c)=>c.charCodeAt(0));
    const command = new AnalyzeDocumentCommand({
      Document: {
        Bytes: imageBytes
      },
      FeatureTypes: [
        'FORMS',
        'TABLES'
      ]
    });
    const textractResponse = await textractClient.send(command);
    // Extract text and calculate confidence
    let extractedText = '';
    let totalConfidence = 0;
    let blockCount = 0;
    textractResponse.Blocks?.forEach((block)=>{
      if (block.BlockType === 'LINE') {
        extractedText += (block.Text || '') + '\n';
        if (block.Confidence) {
          totalConfidence += block.Confidence;
          blockCount++;
        }
      }
    });
    const averageConfidence = blockCount > 0 ? totalConfidence / blockCount : 0;
    // Basic validation
    const MINIMUM_CONFIDENCE = 70;
    const MINIMUM_TEXT_LENGTH = 20;
    const passedConfidence = averageConfidence >= MINIMUM_CONFIDENCE;
    const passedTextLength = extractedText.trim().length >= MINIMUM_TEXT_LENGTH;
    // PCAB-specific validation
    let pcabValidation = {
      isValid: false,
      score: 0,
      findings: {},
      reasons: [
        'Not a PCAB document'
      ]
    };
    if (documentType === 'pcab' && passedConfidence && passedTextLength) {
      pcabValidation = validatePCABDocument(extractedText);
    }
    // Overall verification result
    const verificationPassed = passedConfidence && passedTextLength && pcabValidation.isValid;
    // Build failure reasons
    const failureReasons = [];
    if (!passedConfidence) {
      failureReasons.push(`Low confidence: ${averageConfidence.toFixed(1)}% (need ${MINIMUM_CONFIDENCE}%)`);
    }
    if (!passedTextLength) {
      failureReasons.push(`Not enough text: ${extractedText.length} characters (need ${MINIMUM_TEXT_LENGTH}+)`);
    }
    if (documentType === 'pcab' && !pcabValidation.isValid) {
      failureReasons.push(`PCAB validation failed (${pcabValidation.score}/100): ${pcabValidation.reasons.join(', ')}`);
    }
    // Save to database
    const { data: textractResult } = await supabaseClient.from('textract_results').insert({
      document_id: documentId,
      extracted_text: extractedText.trim(),
      confidence_score: averageConfidence,
      verification_status: verificationPassed ? 'verified' : 'failed',
      verification_reasons: failureReasons,
      raw_textract_response: textractResponse
    }).select().single();
    // Update document with final status
    await supabaseClient.from('documents').update({
      processing_status: verificationPassed ? 'verified' : 'failed',
      verification_details: {
        pcab_validation: pcabValidation,
        confidence: averageConfidence,
        document_type: documentType
      }
    }).eq('id', documentId);
    // Log the result
    await supabaseClient.from('processing_logs').insert({
      document_id: documentId,
      log_level: verificationPassed ? 'info' : 'warning',
      message: verificationPassed ? `PCAB document verified successfully (Score: ${pcabValidation.score}/100, Confidence: ${averageConfidence.toFixed(1)}%)` : `PCAB document verification failed: ${failureReasons.join(', ')}`
    });
    // Return detailed result
    return new Response(JSON.stringify({
      success: verificationPassed,
      verified: verificationPassed,
      extractedText: extractedText.trim(),
      confidence: Math.round(averageConfidence),
      pcabScore: pcabValidation.score,
      pcabFindings: pcabValidation.findings,
      reasons: failureReasons,
      resultId: textractResult.id
    }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      }
    });
  } catch (error) {
    console.error('Error:', error);
    return new Response(JSON.stringify({
      success: false,
      verified: false,
      error: error.message
    }), {
      status: 500,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      }
    });
  }
});


_______________________________________________________________________________________

-- tables supabase -- 

-- Add verification columns to textract_results table
ALTER TABLE textract_results ADD COLUMN verification_status TEXT DEFAULT 'pending' 
  CHECK (verification_status IN ('pending', 'verified', 'failed', 'manual_review'));
ALTER TABLE textract_results ADD COLUMN verification_reasons JSONB;
ALTER TABLE textract_results ADD COLUMN verification_type TEXT;
ALTER TABLE textract_results ADD COLUMN manual_review_required BOOLEAN DEFAULT FALSE;

-- Add verification details to documents table
ALTER TABLE documents ADD COLUMN verification_details JSONB;


-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Documents table - stores document metadata
CREATE TABLE documents (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    original_filename TEXT NOT NULL,
    file_size INTEGER,
    file_type TEXT NOT NULL,
    s3_url TEXT, -- if storing files in S3
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processing_status TEXT DEFAULT 'pending' CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Textract results table - stores extracted text and analysis
CREATE TABLE textract_results (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
    extracted_text TEXT,
    confidence_score DECIMAL(5,2),
    processing_time_ms INTEGER,
    textract_job_id TEXT, -- for async operations
    raw_textract_response JSONB, -- store full Textract response
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Document blocks table - for detailed Textract block analysis
CREATE TABLE document_blocks (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    textract_result_id UUID REFERENCES textract_results(id) ON DELETE CASCADE,
    block_type TEXT NOT NULL, -- LINE, WORD, TABLE, FORM, etc.
    text_content TEXT,
    confidence DECIMAL(5,2),
    bounding_box JSONB, -- store coordinates
    page_number INTEGER DEFAULT 1,
    block_index INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Key-value pairs table - for form data extraction
CREATE TABLE extracted_key_values (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    textract_result_id UUID REFERENCES textract_results(id) ON DELETE CASCADE,
    key_text TEXT NOT NULL,
    value_text TEXT,
    confidence DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tables data - for extracted table information
CREATE TABLE extracted_tables (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    textract_result_id UUID REFERENCES textract_results(id) ON DELETE CASCADE,
    table_index INTEGER,
    rows_count INTEGER,
    columns_count INTEGER,
    table_data JSONB, -- store table as JSON
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Processing logs - for debugging and monitoring
CREATE TABLE processing_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
    log_level TEXT DEFAULT 'info' CHECK (log_level IN ('debug', 'info', 'warning', 'error')),
    message TEXT NOT NULL,
    error_details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_documents_user_id ON documents(user_id);
CREATE INDEX idx_documents_status ON documents(processing_status);
CREATE INDEX idx_textract_results_document_id ON textract_results(document_id);
CREATE INDEX idx_document_blocks_result_id ON document_blocks(textract_result_id);
CREATE INDEX idx_document_blocks_type ON document_blocks(block_type);
CREATE INDEX idx_extracted_kv_result_id ON extracted_key_values(textract_result_id);
CREATE INDEX idx_extracted_tables_result_id ON extracted_tables(textract_result_id);
CREATE INDEX idx_processing_logs_document_id ON processing_logs(document_id);

-- Enable Row Level Security (RLS)
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE textract_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE extracted_key_values ENABLE ROW LEVEL SECURITY;
ALTER TABLE extracted_tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE processing_logs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can only see their own documents" ON documents
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can only see their own textract results" ON textract_results
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM documents 
            WHERE documents.id = textract_results.document_id 
            AND documents.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can only see their own document blocks" ON document_blocks
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM textract_results tr
            JOIN documents d ON d.id = tr.document_id
            WHERE tr.id = document_blocks.textract_result_id 
            AND d.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can only see their own extracted key-values" ON extracted_key_values
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM textract_results tr
            JOIN documents d ON d.id = tr.document_id
            WHERE tr.id = extracted_key_values.textract_result_id 
            AND d.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can only see their own extracted tables" ON extracted_tables
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM textract_results tr
            JOIN documents d ON d.id = tr.document_id
            WHERE tr.id = extracted_tables.textract_result_id 
            AND d.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can only see their own processing logs" ON processing_logs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM documents 
            WHERE documents.id = processing_logs.document_id 
            AND documents.user_id = auth.uid()
        )
    );


_______________________________________________________________________________________________

-- success example -- 

{
  "success": true,
  "verified": true,
  "pcabScore": 90,
  "pcabFindings": {
    "hasPCABText": true,
    "hasLicenseNumber": true,
    "hasCategory": true,
    "licenseNumbers": ["PCAB-2024-001234"],
    "categories": ["Category A"]
  }
}


-- failure example -- 

{
  "success": false,
  "verified": false,
  "pcabScore": 25,
  "reasons": [
    "PCAB validation failed (25/100): No valid license number found, No contractor category found"
  ]
}


✅ PCAB Text Presence (25 points): "PCAB", "Philippine Contractors Accreditation Board" ✅ License Numbers (30 points): PCAB1234, License No: 1234, etc. ✅ Categories (20 points): Category A, Class B, etc. ✅ Valid Dates (15 points): Issue/expiry dates in various formats ✅ Company Indicators (10 points): Corporation, Construction, Contractor, etc.

