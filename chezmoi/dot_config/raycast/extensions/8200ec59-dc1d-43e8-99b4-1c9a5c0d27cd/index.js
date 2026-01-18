"use strict";var Z=Object.create;var $=Object.defineProperty;var q=Object.getOwnPropertyDescriptor;var Y=Object.getOwnPropertyNames;var X=Object.getPrototypeOf,Q=Object.prototype.hasOwnProperty;var ee=(r,t)=>{for(var e in t)$(r,e,{get:t[e],enumerable:!0})},I=(r,t,e,n)=>{if(t&&typeof t=="object"||typeof t=="function")for(let a of Y(t))!Q.call(r,a)&&a!==e&&$(r,a,{get:()=>t[a],enumerable:!(n=q(t,a))||n.enumerable});return r};var v=(r,t,e)=>(e=r!=null?Z(X(r)):{},I(t||!r||!r.__esModule?$(e,"default",{value:r,enumerable:!0}):e,r)),te=r=>I($({},"__esModule",{value:!0}),r);var ce={};ee(ce,{default:()=>oe});module.exports=te(ce);var o=require("@raycast/api");var h=v(require("react")),l=require("@raycast/api");var T=v(require("node:child_process")),V=require("node:buffer"),m=v(require("node:stream")),D=require("node:util");var W=require("react/jsx-runtime");var S=globalThis;var y=r=>!!r&&typeof r=="object"&&typeof r.removeListener=="function"&&typeof r.emit=="function"&&typeof r.reallyExit=="function"&&typeof r.listeners=="function"&&typeof r.kill=="function"&&typeof r.pid=="number"&&typeof r.on=="function",E=Symbol.for("signal-exit emitter"),P=class{constructor(){if(this.emitted={afterExit:!1,exit:!1},this.listeners={afterExit:[],exit:[]},this.count=0,this.id=Math.random(),S[E])return S[E];Object.defineProperty(S,E,{value:this,writable:!1,enumerable:!1,configurable:!1})}on(t,e){this.listeners[t].push(e)}removeListener(t,e){let n=this.listeners[t],a=n.indexOf(e);a!==-1&&(a===0&&n.length===1?n.length=0:n.splice(a,1))}emit(t,e,n){if(this.emitted[t])return!1;this.emitted[t]=!0;let a=!1;for(let s of this.listeners[t])a=s(e,n)===!0||a;return t==="exit"&&(a=this.emit("afterExit",e,n)||a),a}},C=class{onExit(){return()=>{}}load(){}unload(){}},R=class{#o;#t;#e;#s;#i;#a;#n;#r;constructor(t){this.#o=process.platform==="win32"?"SIGINT":"SIGHUP",this.#t=new P,this.#a={},this.#n=!1,this.#r=[],this.#r.push("SIGHUP","SIGINT","SIGTERM"),globalThis.process.platform!=="win32"&&this.#r.push("SIGALRM","SIGABRT","SIGVTALRM","SIGXCPU","SIGXFSZ","SIGUSR2","SIGTRAP","SIGSYS","SIGQUIT","SIGIOT"),globalThis.process.platform==="linux"&&this.#r.push("SIGIO","SIGPOLL","SIGPWR","SIGSTKFLT"),this.#e=t,this.#a={};for(let e of this.#r)this.#a[e]=()=>{let n=this.#e.listeners(e),{count:a}=this.#t,s=t;if(typeof s.__signal_exit_emitter__=="object"&&typeof s.__signal_exit_emitter__.count=="number"&&(a+=s.__signal_exit_emitter__.count),n.length===a){this.unload();let i=this.#t.emit("exit",null,e),c=e==="SIGHUP"?this.#o:e;i||t.kill(t.pid,c)}};this.#i=t.reallyExit,this.#s=t.emit}onExit(t,e){if(!y(this.#e))return()=>{};this.#n===!1&&this.load();let n=e?.alwaysLast?"afterExit":"exit";return this.#t.on(n,t),()=>{this.#t.removeListener(n,t),this.#t.listeners.exit.length===0&&this.#t.listeners.afterExit.length===0&&this.unload()}}load(){if(!this.#n){this.#n=!0,this.#t.count+=1;for(let t of this.#r)try{let e=this.#a[t];e&&this.#e.on(t,e)}catch{}this.#e.emit=(t,...e)=>this.#l(t,...e),this.#e.reallyExit=t=>this.#c(t)}}unload(){this.#n&&(this.#n=!1,this.#r.forEach(t=>{let e=this.#a[t];if(!e)throw new Error("Listener not defined for signal: "+t);try{this.#e.removeListener(t,e)}catch{}}),this.#e.emit=this.#s,this.#e.reallyExit=this.#i,this.#t.count-=1)}#c(t){return y(this.#e)?(this.#e.exitCode=t||0,this.#t.emit("exit",this.#e.exitCode,null),this.#i.call(this.#e,this.#e.exitCode)):0}#l(t,...e){let n=this.#s;if(t==="exit"&&y(this.#e)){typeof e[0]=="number"&&(this.#e.exitCode=e[0]);let a=n.call(this.#e,t,...e);return this.#t.emit("exit",this.#e.exitCode,null),a}else return n.call(this.#e,t,...e)}},A=null,re=(r,t)=>(A||(A=y(process)?new R(process):new C),A.onExit(r,t));function L(r,{timeout:t}={}){let e=new Promise((c,u)=>{r.on("exit",(f,d)=>{c({exitCode:f,signal:d,timedOut:!1})}),r.on("error",f=>{u(f)}),r.stdin&&r.stdin.on("error",f=>{u(f)})}),n=re(()=>{r.kill()});if(t===0||t===void 0)return e.finally(()=>n());let a,s=new Promise((c,u)=>{a=setTimeout(()=>{r.kill("SIGTERM"),u(Object.assign(new Error("Timed out"),{timedOut:!0,signal:"SIGTERM"}))},t)}),i=e.finally(()=>{clearTimeout(a)});return Promise.race([s,i]).finally(()=>n())}var _=class extends Error{constructor(){super("The output is too big"),this.name="MaxBufferError"}};function ne(r){let{encoding:t}=r,e=t==="buffer",n=new m.default.PassThrough({objectMode:!1});t&&t!=="buffer"&&n.setEncoding(t);let a=0,s=[];return n.on("data",i=>{s.push(i),a+=i.length}),n.getBufferedValue=()=>e?Buffer.concat(s,a):s.join(""),n.getBufferedLength=()=>a,n}async function O(r,t){let e=ne(t);return await new Promise((n,a)=>{let s=i=>{i&&e.getBufferedLength()<=V.constants.MAX_LENGTH&&(i.bufferedData=e.getBufferedValue()),a(i)};(async()=>{try{await(0,D.promisify)(m.default.pipeline)(r,e),n()}catch(i){s(i)}})(),e.on("data",()=>{e.getBufferedLength()>8e7&&s(new _)})}),e.getBufferedValue()}async function M(r,t){r.destroy();try{return await t}catch(e){return e.bufferedData}}async function F({stdout:r,stderr:t},{encoding:e},n){let a=O(r,{encoding:e}),s=O(t,{encoding:e});try{return await Promise.all([n,a,s])}catch(i){return Promise.all([{error:i,exitCode:null,signal:i.signal,timedOut:i.timedOut||!1},M(r,a),M(t,s)])}}function ae(r){let t=typeof r=="string"?`
`:10,e=typeof r=="string"?"\r":13;return r[r.length-1]===t&&(r=r.slice(0,-1)),r[r.length-1]===e&&(r=r.slice(0,-1)),r}function w(r,t){return r.stripFinalNewline?ae(t):t}function se({timedOut:r,timeout:t,signal:e,exitCode:n}){return r?`timed out after ${t} milliseconds`:e!=null?`was killed with ${e}`:n!=null?`failed with exit code ${n}`:"failed"}function ie({stdout:r,stderr:t,error:e,signal:n,exitCode:a,command:s,timedOut:i,options:c,parentError:u}){let d=`Command ${se({timedOut:i,timeout:c?.timeout,signal:n,exitCode:a})}: ${s}`,p=e?`${d}
${e.message}`:d,b=[p,t,r].filter(Boolean).join(`
`);return e?e.originalMessage=e.message:e=u,e.message=b,e.shortMessage=p,e.command=s,e.exitCode=a,e.signal=n,e.stdout=r,e.stderr=t,"bufferedData"in e&&delete e.bufferedData,e}function z({stdout:r,stderr:t,error:e,exitCode:n,signal:a,timedOut:s,command:i,options:c,parentError:u}){if(e||n!==0||a!==null)throw ie({error:e,exitCode:n,signal:a,stdout:r,stderr:t,command:i,timedOut:s,options:c,parentError:u});return r}async function N(r,t,e){if(process.platform!=="darwin")throw new Error("AppleScript is only supported on macOS");let{humanReadableOutput:n,language:a,timeout:s,...i}=Array.isArray(t)?e||{}:t||{},c=n!==!1?[]:["-ss"];a==="JavaScript"&&c.push("-l","JavaScript"),Array.isArray(t)&&c.push("-",...t);let u=T.default.spawn("osascript",c,{...i,env:{PATH:"/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"}}),f=L(u,{timeout:s??1e4});u.stdin.end(r);let[{error:d,exitCode:p,signal:b,timedOut:k},x,K]=await F(u,{encoding:"utf8"},f),H=w({stripFinalNewline:!0},x),J=w({stripFinalNewline:!0},K);return z({stdout:H,stderr:J,error:d,exitCode:p,signal:b,timedOut:k,command:"osascript",options:e,parentError:new Error})}async function U(r,t){if(process.platform!=="win32")throw new Error("PowerShell is only supported on Windows");let{timeout:e,...n}=t||{},a=["-NoLogo","-NoProfile","-NonInteractive","-Command","-"],s=T.default.spawn("powershell.exe",a,{...n}),i=L(s,{timeout:e??1e4});s.stdin.end(r);let[{error:c,exitCode:u,signal:f,timedOut:d},p,b]=await F(s,{encoding:"utf8"},i),k=w({stripFinalNewline:!0},p),x=w({stripFinalNewline:!0},b);return z({stdout:k,stderr:x,error:c,exitCode:u,signal:f,timedOut:d,command:"powershell.exe",options:t,parentError:new Error})}var g=process.platform==="darwin",j=async()=>{let r=`
  if application "Finder" is running and frontmost of application "Finder" then
    tell app "Finder"
      set finderWindow to window 1
      set finderWindowPath to (POSIX path of (target of finderWindow as alias))
      return finderWindowPath
    end tell
  else 
    error "Could not get the selected Finder window"
  end if
 `;try{return(await N(r)).trim()}catch{throw new Error("Could not get the selected Finder window")}},B=async()=>(await U(`
function Get-SelectedExplorerItemsInternal {
    [CmdletBinding()]
    Param()
    $shell = New-Object -ComObject Shell.Application
    $selectedPaths = @()
    foreach ($window in $shell.Windows()) {
        try {
            if ($window.Document -and $window.Document.Folder -and $window.Document.SelectedItems) {
                $items = $window.Document.SelectedItems()
                if ($items.Count -gt 0) {
                    foreach ($item in $items) {
                        $selectedPaths += $item.Path
                    }
                    return $selectedPaths
                }
            }
        }
        catch { }
    }
    return $selectedPaths
}
Get-SelectedExplorerItemsInternal | ForEach-Object { Write-Output $_ }
  `)).split(/\r?\n/).filter(n=>n.trim()!=="").flatMap(n=>({path:n})),G=async()=>(await U(`
        function Get-CurrentExplorerPathInternal {
            $shell = New-Object -ComObject Shell.Application
            $foundPath = ""
            foreach ($window in $shell.Windows()) {
                try {
                    if ($window.Document -and $window.Document.Folder -and $window.Document.Folder.Self.Path) {
                        $path = $window.Document.Folder.Self.Path
                        $foundPath = $path
                        break
                    }
                }
                catch { }
            }
            return $foundPath
        }
        Get-CurrentExplorerPathInternal
    `)).trim();var oe=async()=>{let r=(0,o.getPreferenceValues)(),t=await(0,o.getApplications)(),e,a={"com.microsoft.VSCode":"Visual Studio Code","com.microsoft.VSCodeInsiders":"Visual Studio Code - Insiders","com.vscodium":"VSCodium","com.todesktop.230313mzl4w4u92":"Cursor"}[r.VSCodeVariant];if(g?e=t.find(s=>s.bundleId===r.VSCodeVariant):a&&(e=t.find(s=>s.name.includes(a))),!e){await(0,o.showToast)({style:o.Toast.Style.Failure,title:`${a||"Code Editor"} is not installed`,primaryAction:{title:"Install Visual Studio Code",onAction:()=>(0,o.open)("https://code.visualstudio.com/download")},secondaryAction:{title:"Install VSCodium",onAction:()=>(0,o.open)("https://github.com/VSCodium/vscodium/releases")}});return}try{let s=await(g?(0,o.getSelectedFinderItems)():B());if(s.length){for(let c of s)await(0,o.open)(c.path,e);return}let i=await(g?j():G());if(!i)throw new Error;await(0,o.open)(i,e)}catch{let s=g?"Finder":"File Explorer";await(0,o.showToast)({style:o.Toast.Style.Failure,title:`No ${s} items or window selected`})}};
