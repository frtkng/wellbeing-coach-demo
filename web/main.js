const API = "<置換後URL>";  // 後で Outputs の ChatAPI に書換
const log = document.getElementById("log");
function append(text,cls){
  const p=document.createElement("p");p.textContent=text;p.className=cls;log.appendChild(p);log.scrollTop=log.scrollHeight;
}
function send(){
  const m=document.getElementById("msg"); if(!m.value)return;
  append("🧑 "+m.value,"u");
  fetch(API,{method:"POST",headers:{'Content-Type':'application/json'},
        body:JSON.stringify({message:m.value})})
     .then(r=>r.json()).then(r=>append("🤖 "+r.reply,"b"));
  m.value="";
}