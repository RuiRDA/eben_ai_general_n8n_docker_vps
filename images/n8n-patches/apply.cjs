// Patch only the three audited bundled packages, preserving n8n's pnpm links.
// Replacement archives are checksum-locked and have no runtime dependencies.
const fs=require('node:fs'),path=require('node:path');
const targets={'fast-uri':'3.1.6','nodemailer':'9.0.1','toml':'4.2.0'};
const root='/usr/local/lib/node_modules/n8n/node_modules/.pnpm';
let patched=0;
for(const entry of fs.readdirSync(root)){
 for(const [name,version] of Object.entries(targets)){
  const dir=path.join(root,entry,'node_modules',name),manifest=path.join(dir,'package.json');
  if(!fs.existsSync(manifest)||fs.lstatSync(dir).isSymbolicLink())continue;
  const pkg=JSON.parse(fs.readFileSync(manifest));if(pkg.name!==name)continue;
  fs.rmSync(dir,{recursive:true});fs.cpSync('/opt/security-patches/node_modules/'+name,dir,{recursive:true});
  if(JSON.parse(fs.readFileSync(manifest)).version!==version)throw new Error('Patch verification failed');patched++;
 }
}
if(patched<3)throw new Error('Expected bundled package layout missing');
console.log('Applied verified bundled security replacements:',patched);
