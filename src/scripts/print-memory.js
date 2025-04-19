import os from 'os';

const freeMB  = (os.freemem() / 1024 / 1024).toFixed(2);
const totalMB = (os.totalmem() / 1024 / 1024).toFixed(2);

console.log(`Available Memory: ${freeMB} MB / ${totalMB} MB`);
