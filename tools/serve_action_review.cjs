// Local-only static review server. Serves generated artifacts, never the repo root.
const http=require('http'),fs=require('fs'),path=require('path');
const root=path.resolve(__dirname,'../artifacts');
const mime={'.html':'text/html; charset=utf-8','.json':'application/json; charset=utf-8','.png':'image/png','.svg':'image/svg+xml','.mp4':'video/mp4'};
http.createServer((req,res)=>{let name;try{name=decodeURIComponent(new URL(req.url,'http://localhost').pathname)}catch{res.writeHead(400).end();return}const file=path.resolve(root,'.'+name);if(!file.startsWith(root+path.sep)){res.writeHead(403).end();return}fs.stat(file,(error,stat)=>{if(error||!stat.isFile()){res.writeHead(404).end();return}res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Content-Length':stat.size,'Cache-Control':'no-cache'});fs.createReadStream(file).pipe(res)})}).listen(8879,'127.0.0.1',()=>console.log('Review: http://localhost:8879/concept42_action_review.html'));
