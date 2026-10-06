const svgNS="http://www.w3.org/2000/svg";
const fmt=new Intl.NumberFormat("en-GB",{maximumFractionDigits:0});
const pct=x=>(100*x).toFixed(1)+"%";
const num=x=>fmt.format(x);
function svgNode(name,attrs={},text=""){const n=document.createElementNS(svgNS,name);Object.entries(attrs).forEach(([k,v])=>n.setAttribute(k,v));if(text)n.textContent=text;return n;}
function makeChart(container,title,series,{labels=[],money=false,bar=false,height=330}={}){
  const root=document.querySelector(container);root.replaceChildren();
  const w=960,h=height,l=76,r=24,t=22,b=48,pw=w-l-r,ph=h-t-b;
  const svg=svgNode("svg",{viewBox:`0 0 ${w} ${h}`,role:"img","aria-label":title});svg.append(svgNode("title",{},title));
  const max=Math.max(1,...series.flatMap(s=>s.values));const min=Math.min(0,...series.flatMap(s=>s.values));
  const y=v=>t+ph-(v-min)/(max-min)*ph;
  const x=i=>l+(i+.5)/Math.max(1,labels.length)*pw;
  for(let i=0;i<=4;i++){let v=min+(max-min)*i/4;svg.append(svgNode("line",{x1:l,x2:w-r,y1:y(v),y2:y(v),stroke:"#e3e8e8"}));svg.append(svgNode("text",{x:l-12,y:y(v)+4,"text-anchor":"end",fill:"#5a696d","font-size":12},(money?"£":"")+num(v)));}
  series.forEach((s,j)=>{
    if(bar&&j===0){s.values.forEach((v,i)=>{const rect=svgNode("rect",{x:x(i)-pw/labels.length*.32,y:Math.min(y(v),y(0)),width:pw/labels.length*.64,height:Math.max(1,Math.abs(y(v)-y(0))),fill:s.color,tabindex:0});rect.append(svgNode("title",{},`${labels[i]}: ${s.name} ${money?"GBP ":""}${num(v)}`));svg.append(rect);});}
    else{const path=s.values.map((v,i)=>(i?"L":"M")+x(i)+","+y(v)).join(" ");svg.append(svgNode("path",{d:path,fill:"none",stroke:s.color,"stroke-width":2.7}));s.values.forEach((v,i)=>{const circle=svgNode("circle",{cx:x(i),cy:y(v),r:labels.length>100?1.8:3.5,fill:s.color,tabindex:labels.length<50?0:-1});circle.append(svgNode("title",{},`${labels[i]}: ${s.name} ${money?"GBP ":""}${num(v)}`));svg.append(circle);});}
  });
  const every=Math.max(1,Math.ceil(labels.length/12));labels.forEach((label,i)=>{if(i%every===0||i===labels.length-1)svg.append(svgNode("text",{x:x(i),y:h-18,"text-anchor":"middle",fill:"#5a696d","font-size":12},label));});root.append(svg);
}
function table(container,headers,rows){const root=document.querySelector(container);root.replaceChildren();const table=document.createElement("table"),head=document.createElement("thead"),hr=document.createElement("tr");headers.forEach(h=>{const th=document.createElement("th");th.textContent=h;th.scope="col";hr.append(th)});head.append(hr);table.append(head);const body=document.createElement("tbody");rows.forEach(row=>{const tr=document.createElement("tr");row.forEach(v=>{const td=document.createElement("td");td.textContent=v;tr.append(td)});body.append(tr)});table.append(body);root.append(table);}
function exportCSV(name,headers,rows){const esc=v=>'"'+String(v??"").replaceAll('"','""')+'"';const blob=new Blob(["\uFEFF"+[headers,...rows].map(row=>row.map(esc).join(",")).join("\n")],{type:"text/csv;charset=utf-8"});const url=URL.createObjectURL(blob),a=document.createElement("a");a.href=url;a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);document.querySelector("#export-status").textContent="CSV download prepared for the current selection.";}
