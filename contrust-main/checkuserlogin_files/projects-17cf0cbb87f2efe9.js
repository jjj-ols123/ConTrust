!function(){try{var e="undefined"!=typeof window?window:"undefined"!=typeof global?global:"undefined"!=typeof self?self:{},t=(new e.Error).stack;t&&(e._sentryDebugIds=e._sentryDebugIds||{},e._sentryDebugIds[t]="04895478-1b4f-4a29-974a-c39a9c2ad9ec",e._sentryDebugIdIdentifier="sentry-dbid-04895478-1b4f-4a29-974a-c39a9c2ad9ec")}catch(e){}}(),(self.webpackChunk_N_E=self.webpackChunk_N_E||[]).push([[3327],{21949:function(e,t,s){(window.__NEXT_P=window.__NEXT_P||[]).push(["/projects",function(){return s(72074)}])},14567:function(e,t,s){"use strict";s.d(t,{l:function(){return C}});var r=s(97458),n=s(39907),i=s.n(n),a=s(36950),o=s(83145),l=s.n(o),c=s(5529),d=s(76767),u=s(6146),g=s(987),x=s(15501),p=s(24163),m=s(89572),h=s(62715),f=s(63278),j=s(86007),v=s(71147),y=s(37756),N=s(45536),_=s(65092),b=s(90839),w=s(47589),P=s(46753),C=e=>{let{search:t,rewriteHref:s,filterStatus:n,resetFilterStatus:a}=e,{data:o,isLoading:l,isSuccess:c}=(0,m.tl)(),{data:u,isLoading:g,isSuccess:x,isError:v,error:N}=(0,f.Sy)(),{isLoading:w,isError:C,error:A}=(0,h.j)(),{data:E}=(0,j.q)(),{data:z}=(0,p.E)(),H=i()(u,"organization_id"),L=!!y.Qy&&w,Z=void 0!==n&&2!==n.length,k=t.length>0&&x&&0===u.filter(e=>e.name.toLowerCase().includes(t.toLowerCase())||e.ref.includes(t.toLowerCase())).length,T=Z&&x&&0===u.filter(e=>n.includes(e.status)).length;return l?(0,r.jsxs)("ul",{className:"mx-auto grid grid-cols-1 gap-4 sm:grid-cols-1 md:grid-cols-1 lg:grid-cols-2 xl:grid-cols-3",children:[(0,r.jsx)(P.Z,{}),(0,r.jsx)(P.Z,{})]}):k?(0,r.jsx)(d.Z,{searchString:t}):T?(0,r.jsxs)("div",{className:(0,_.cn)("bg-surface-100 border border-default px-4 md:px-6 py-4 rounded flex items-center justify-between"),children:[(0,r.jsxs)("div",{className:"space-y-1",children:[(0,r.jsx)("p",{className:"text-sm text-foreground",children:0===n.length?"No projects found":"No ".concat("INACTIVE"===n[0]?"paused":"active"," projects found")}),(0,r.jsx)("p",{className:"text-sm text-foreground-light",children:"Your search for projects with the specified status did not return any results"})]}),void 0!==a&&(0,r.jsx)(b.z,{type:"default",onClick:()=>a(),children:"Reset filter"})]}):c&&o&&(null==o?void 0:o.length)>0?(0,r.jsx)(r.Fragment,{children:null==o?void 0:o.map(e=>(0,r.jsx)(S,{organization:e,projects:H[e.id],overdueInvoices:(null!=z?z:[]).filter(t=>t.organization_id===e.id),resourceWarnings:null!=E?E:[],rewriteHref:s,isLoadingPermissions:L,isErrorPermissions:C,permissionsError:A,isLoadingProjects:g,isErrorProjects:v,projectsError:N,search:t,filterStatus:n},e.slug))}):(0,r.jsx)(I,{slug:"","data-sentry-element":"NoProjectsState","data-sentry-component":"ProjectList","data-sentry-source-file":"ProjectList.tsx"})};let S=e=>{let{organization:t,projects:s,overdueInvoices:n,resourceWarnings:i,isLoadingPermissions:a,isErrorPermissions:o,permissionsError:d,isLoadingProjects:p,isErrorProjects:m,projectsError:h,rewriteHref:f,search:j,filterStatus:v}=e,y=!s||0===s.length,_=[...s||[]].sort((e,t)=>e.name.localeCompare(t.name)),C=j.length>0?_.filter(e=>e.name.toLowerCase().includes(j.toLowerCase())||e.ref.includes(j.toLowerCase())):_,S=void 0!==v?2===v.length?C:C.filter(e=>v.includes(e.status)):C,{data:A}=(0,x.T)({orgSlug:null==t?void 0:t.slug}),{data:E}=(0,g.q)({organizationId:null==t?void 0:t.id}),z=null==E?void 0:E.map(e=>{var t,s,r,n,i;return{id:String(e.id),added_by:{id:String(null===(t=e.user)||void 0===t?void 0:t.id),primary_email:null!==(n=null===(s=e.user)||void 0===s?void 0:s.primary_email)&&void 0!==n?n:"",username:null!==(i=null===(r=e.user)||void 0===r?void 0:r.username)&&void 0!==i?i:""},foreign_project_id:String(e.repository.id),supabase_project_ref:e.project.ref,organization_integration_id:"unused",inserted_at:e.inserted_at,updated_at:e.updated_at,metadata:{name:e.repository.name}}}),H=null==A?void 0:A.filter(e=>"Vercel"===e.integration.name).flatMap(e=>e.connections);return(j.length>0||void 0!==v&&2!==v.length)&&0===S.length?null:(0,r.jsxs)("div",{className:"space-y-3","data-sentry-component":"OrganizationProjects","data-sentry-source-file":"ProjectList.tsx",children:[(0,r.jsxs)("div",{className:"flex space-x-4 items-center",children:[(0,r.jsxs)("div",{className:"flex items-center gap-2",children:[(0,r.jsx)("h4",{className:"text-lg flex items-center",children:t.name})," ",(0,r.jsx)(u.Z,{organization:t,"data-sentry-element":"PartnerIcon","data-sentry-source-file":"ProjectList.tsx"})]}),!!n.length&&(0,r.jsx)("div",{children:(0,r.jsx)(b.z,{asChild:!0,type:"danger",children:(0,r.jsx)(l(),{href:"/org/".concat(t.slug,"/invoices"),children:"Outstanding Invoices"})})}),(null==t?void 0:t.restriction_status)==="grace_period"&&(0,r.jsx)("div",{children:(0,r.jsx)(b.z,{asChild:!0,type:"warning",children:(0,r.jsx)(l(),{href:"/org/".concat(t.slug,"/billing"),children:"Grace Period"})})}),(null==t?void 0:t.restriction_status)==="grace_period_over"&&(0,r.jsx)("div",{children:(0,r.jsx)(b.z,{asChild:!0,type:"warning",children:(0,r.jsx)(l(),{href:"/org/".concat(t.slug,"/billing"),children:"Grace Period Over"})})}),(null==t?void 0:t.restriction_status)==="restricted"&&(0,r.jsx)("div",{children:(0,r.jsx)(b.z,{asChild:!0,type:"danger",children:(0,r.jsx)(l(),{href:"/org/".concat(t.slug,"/billing"),children:"Services Restricted"})})})]}),a||p?(0,r.jsxs)("ul",{className:"mx-auto grid grid-cols-1 gap-4 sm:grid-cols-1 md:grid-cols-1 lg:grid-cols-2 xl:grid-cols-3",children:[(0,r.jsx)(P.Z,{}),(0,r.jsx)(P.Z,{})]}):(0,r.jsx)("ul",{className:"mx-auto grid grid-cols-1 gap-2 md:gap-4 sm:grid-cols-1 md:grid-cols-1 lg:grid-cols-2 xl:grid-cols-3",children:o?(0,r.jsx)("div",{className:"col-span-3",children:(0,r.jsx)(c.Z,{subject:"Failed to retrieve permissions for your account",error:d})}):m?(0,r.jsx)("div",{className:"col-span-3",children:(0,r.jsx)(c.Z,{subject:"Failed to retrieve projects under ".concat(name),error:h})}):y?(0,r.jsx)(I,{slug:t.slug}):null==S?void 0:S.map(e=>(0,r.jsx)(w.Z,{project:e,rewriteHref:f?f(e.ref):void 0,resourceWarnings:i.find(t=>t.project===e.ref),githubIntegration:null==z?void 0:z.find(t=>t.supabase_project_ref===e.ref),vercelIntegration:null==H?void 0:H.find(t=>t.supabase_project_ref===e.ref)},(0,N.pZ)(5)))})]},t.slug)},I=e=>{let{slug:t}=e,s=(0,v.N)("projects:create");return(0,r.jsxs)("div",{className:"col-span-4 space-y-4 rounded-lg border border-dashed p-6 text-center","data-sentry-component":"NoProjectsState","data-sentry-source-file":"ProjectList.tsx",children:[(0,r.jsxs)("div",{className:"space-y-1",children:[(0,r.jsx)("p",{children:"No projects"}),(0,r.jsx)("p",{className:"text-sm text-foreground-light",children:"Get started by creating a new project."})]}),s&&(0,r.jsx)(b.z,{asChild:!0,icon:(0,r.jsx)(a.Z,{}),children:(0,r.jsx)(l(),{href:"/new/".concat(t),children:"New Project"})})]})}},24163:function(e,t,s){"use strict";s.d(t,{E:function(){return l}});var r=s(28894),n=s(6464),i=s(65093),a=s(37756);async function o(e){let{data:t,error:s}=await (0,n.U2)("/platform/stripe/invoices/overdue",{signal:e});return s&&(0,n.S3)(s),t}let l=function(){let{enabled:e=!0,...t}=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{};return(0,r.a)(i.Y.overdueInvoices(),e=>{let{signal:t}=e;return o(t)},{enabled:e&&a.Qy,...t})}},65093:function(e,t,s){"use strict";s.d(t,{Y:function(){return r}});let r={overdueInvoices:()=>["invoices","overdue"],invoice:e=>["invoice",e],list:(e,t)=>["invoices",e,t],count:e=>["invoices",e,"count"],listAndCount:e=>["invoices",e],projectInvoices:(e,t)=>["invoices",e,t],projectInvoicesCount:e=>["invoices",e,"count"],orgUpcomingPreview:e=>["invoices",e,"upcoming-preview"]}},86007:function(e,t,s){"use strict";s.d(t,{q:function(){return l}});var r=s(28894),n=s(12436),i=s(6464),a=s(5731);async function o(e){let{data:t,error:s}=await (0,i.U2)("/platform/projects-resource-warnings",{signal:e});return s&&(0,i.S3)(s),t}let l=function(){let{enabled:e=!0,...t}=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{};return(0,r.a)(a.Z.resourceWarnings(),e=>{let{signal:t}=e;return o(t)},{enabled:n.Qy&&e,staleTime:18e5,...t})}},41957:function(e,t,s){"use strict";s.d(t,{Z:function(){return r}});let r=(0,s(98266).Z)("Filter",[["polygon",{points:"22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3",key:"1yg77f"}]])},76767:function(e,t,s){"use strict";var r=s(97458),n=s(65092),i=s(90839);t.Z=e=>{let{searchString:t,onResetFilter:s,className:a}=e;return(0,r.jsxs)("div",{className:(0,n.cn)("bg-surface-100 border border-default px-6 py-4 rounded flex items-center justify-between",a),"data-sentry-component":"NoSearchResults","data-sentry-source-file":"NoSearchResults.tsx",children:[(0,r.jsxs)("div",{className:"space-y-1",children:[(0,r.jsx)("p",{className:"text-sm text-foreground",children:"No results found"}),(0,r.jsxs)("p",{className:"text-sm text-foreground-light",children:['Your search for "',t,'" did not return any results']})]}),void 0!==s&&(0,r.jsx)(i.z,{type:"default",onClick:()=>s(),children:"Reset filter"})]})}},72074:function(e,t,s){"use strict";s.r(t),s.d(t,{default:function(){return I}});var r=s(97458),n=s(32691),i=s(52983),a=s(14567),o=s(77270),l=s(41957),c=s(83145),d=s.n(c),u=s(12436),g=s(89572),x=s(71147),p=s(37756),m=s(56844),h=s(14500),f=s(90839),j=s(51571),v=s(42026),y=s(61893),N=s(36155),_=s(21786),b=e=>{let{organizations:t=m.Z6,search:s,filterStatus:i,setSearch:a,setFilterStatus:c}=e,b=(0,n.useRouter)(),w=(0,x.N)("organizations:create"),{isSuccess:P}=(0,g.tl)(),C="group-b"===(0,_.P)("projectCreationExperimentGroup")?"/new/v2":"/new";return(0,r.jsxs)("div",{className:"flex flex-col gap-2 md:gap-3 md:flex-row","data-sentry-component":"HomePageActions","data-sentry-source-file":"HomePageActions.tsx",children:[(0,r.jsxs)(h.h_,{"data-sentry-element":"DropdownMenu","data-sentry-source-file":"HomePageActions.tsx",children:[(0,r.jsx)(h.$F,{asChild:!0,"data-sentry-element":"DropdownMenuTrigger","data-sentry-source-file":"HomePageActions.tsx",children:(0,r.jsx)(f.z,{type:"primary","data-sentry-element":"Button","data-sentry-source-file":"HomePageActions.tsx",children:(0,r.jsx)("span",{children:"New project"})})}),(0,r.jsx)(h.AW,{side:"bottom",align:"center","data-sentry-element":"DropdownMenuContent","data-sentry-source-file":"HomePageActions.tsx",children:(0,r.jsxs)(r.Fragment,{children:[(0,r.jsx)(h.Ju,{"data-sentry-element":"DropdownMenuLabel","data-sentry-source-file":"HomePageActions.tsx",children:"Choose organization"}),t.sort((e,t)=>e.name.localeCompare(t.name)).map(e=>(0,r.jsx)(h.Xi,{onClick:()=>b.push("".concat(C,"/").concat(e.slug)),children:e.name},e.slug))]})})]}),u.Qy&&w&&P&&(0,r.jsx)(f.z,{type:"default",asChild:!0,children:(0,r.jsx)(d(),{href:"/new",className:"flex items-center gap-2",children:"New organization"})}),(0,r.jsxs)("div",{className:"flex items-center gap-2",children:[(0,r.jsx)(j.Z,{size:"tiny",placeholder:"Search for a project",icon:(0,r.jsx)(o.Z,{size:16}),className:"w-full flex-1 md:w-64 [&>div>div>div>input]:!pl-7 [&>div>div>div>div]:!pl-2",value:s,onChange:e=>a(e.target.value),"data-sentry-element":"Input","data-sentry-source-file":"HomePageActions.tsx"}),(0,r.jsxs)(v.J2,{"data-sentry-element":"Popover_Shadcn_","data-sentry-source-file":"HomePageActions.tsx",children:[(0,r.jsx)(v.xo,{asChild:!0,"data-sentry-element":"PopoverTrigger_Shadcn_","data-sentry-source-file":"HomePageActions.tsx",children:(0,r.jsx)(f.z,{type:2!==i.length?"secondary":"dashed",className:"h-[26px] w-[26px]",icon:(0,r.jsx)(l.Z,{}),"data-sentry-element":"Button","data-sentry-source-file":"HomePageActions.tsx"})}),(0,r.jsx)(v.yk,{className:"p-0 w-56",side:"bottom",align:"center","data-sentry-element":"PopoverContent_Shadcn_","data-sentry-source-file":"HomePageActions.tsx",children:(0,r.jsxs)("div",{className:"px-3 pt-3 pb-2 flex flex-col gap-y-2",children:[(0,r.jsx)("p",{className:"text-xs",children:"Filter projects by status"}),(0,r.jsx)("div",{className:"flex flex-col",children:[{key:p.S.ACTIVE_HEALTHY,label:"Active"},{key:p.S.INACTIVE,label:"Paused"}].map(e=>{let{key:t,label:s}=e;return(0,r.jsxs)("div",{className:"group flex items-center justify-between py-0.5",children:[(0,r.jsxs)("div",{className:"flex items-center gap-x-2",children:[(0,r.jsx)(y.X,{id:t,name:t,checked:i.includes(t),onCheckedChange:()=>{i.includes(t)?c(i.filter(e=>e!==t)):c(i.concat([t]))}}),(0,r.jsx)(N._,{htmlFor:t,className:"capitalize text-xs",children:s})]}),(0,r.jsx)(f.z,{size:"tiny",type:"default",onClick:()=>c([t]),className:"transition opacity-0 group-hover:opacity-100 h-auto px-1 py-0.5",children:"Select only"})]},t)})})]})})]})]})]})},w=s(81558),P=s(5529),C=s(63278);let S=()=>{let e=(0,n.useRouter)(),[t,s]=(0,i.useState)(""),[o,l]=(0,i.useState)([p.S.ACTIVE_HEALTHY,p.S.INACTIVE]),{data:c,isError:d,isSuccess:u}=(0,g.tl)();(0,C.sc)();let m=(0,x.N)("projects:create");return(0,i.useEffect)(()=>{if(u){let t=0===c.length,s=localStorage.getItem(p.dA.UI_ONBOARDING_NEW_PAGE_SHOWN);t&&!s&&(localStorage.setItem(p.dA.UI_ONBOARDING_NEW_PAGE_SHOWN,"true"),e.push("/new"))}},[u,!0]),(0,r.jsxs)(r.Fragment,{children:[d&&(0,r.jsx)("div",{className:"p-4 md:px-5",children:(0,r.jsx)(P.Z,{subject:"Failed to retrieve organizations"})}),(0,r.jsxs)("div",{className:"p-4 md:p-5",children:[p.Qy&&m&&u&&(0,r.jsx)(b,{search:t,filterStatus:o,setSearch:s,setFilterStatus:l,organizations:c}),(0,r.jsx)("div",{className:"my-6 space-y-8",children:(0,r.jsx)(a.l,{search:t,filterStatus:o,resetFilterStatus:()=>l(["ACTIVE_HEALTHY","INACTIVE"]),"data-sentry-element":"ProjectList","data-sentry-source-file":"projects.tsx"})})]})]})};S.getLayout=e=>(0,r.jsx)(w.Z,{title:"Dashboard",breadcrumbs:[{key:"supabase-projects",label:"Projects"}],children:e});var I=S}},function(e){e.O(0,[7623,588,7037,783,6402,1864,1018,4975,4376,9621,3954,3781,3733,8069,4187,4847,1379,2047,1558,5227,9774,2888,179],function(){return e(e.s=21949)}),_N_E=e.O()}]);