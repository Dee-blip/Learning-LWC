//Normal Export
// one way to export the files
// export const PI=3.14;
// export function add(a,b){
//     console.log(a+b)
// }
// Second way
const PI_DATA=3.14;
function add(a,b){
    console.log(a+b)
}
// export {PI,add}

// Export with alias name
export {PI_DATA as PI, add}

// Export with default

// export default function min(a,b){
//     console.log(a-b);
// }

export  function min(a,b){
    console.log(a-b);
}
