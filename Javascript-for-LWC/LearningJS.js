

// // let course1="Hey lets start"
// // console.log(course1);
// // console.log(window.course1);
// // var course2="Hey lets start"
// // console.log(course2);
// // console.log(window.course2);
// // const course3="Hey lets start"
// // console.log(course3);
// // console.log(window.course12);


// function xyz()
// {
//     let course1="Hey lets start1";
//     console.log(course1);
//     var course2="Hey lets start2";
//     console.log(course2);
//     const course3="Hey lets start3";
//     console.log(course3);

// }
// xyz()
// console.log(course1);
// console.log(course2);
// console.log(course3);


// if (2==2)
// {
//     let course1="Hey lets start1";
//     console.log(course1);
//     var course2="Hey lets start2";
//     console.log(course2);
//     const course3="Hey lets start3";
//     console.log(course3);

// }

// // console.log(course1);
// console.log(course2);
// // console.log(course3);

// // big int
// var y=101212n;
// console.log(typeof(y));


// // // array is a type of object

// // // symbol - unique identifier
// // var sym=Symbol("id")
// // console.log(typeof(sym));

// // // null is the object 

// // //Spread Operator

// // // 1. expanding of String
// let gree="Welcome to the world"
// let char=[...gree]
// console.log(char[0]);

// 2.Combining array
// let arr1=["Salesforce",'Amaon','Google']
// let arr2=["1","2","3"]

// let arr3=[...arr1,...arr2]
// console.log(arr3) 


// // // adding value to the array

// // let arr4=["a","b","c"]
// // let arr5=["nikhil",...arr4]
// // console.log(arr5)


// // // combining objects
// // let o1={name:"name",first:"first"}
// // let o2={name:"n1",age:"12"}
// // console.log({...o1,...o2});


// // //shallow copy - never use push operator becoz when we do changes in next arr1 so the changes also reflecting in original array.
// var arr=["x","y","z"]
// arr.push(20)
// console.log(arr);
// var arr12=arr
// arr12.push("za")
// console.log(arr);
// console.log(arr12);

// //   to avoid this - if we use spread operator [...arr_name] shallow copy only works in one level either its array or objects
// // var ar=["x","y","z"]
// // var arr112=[...ar]
// // arr112.push("nikhil")
// // console.log(arr112);
// // console.log(ar);


// // Nested Copy
// // var arro1=[{name:"nikhil"},{age:"12"}]
// // var arro2=[...arro1];
// // console.log(arro1);
// // console.log(arro2);
// // arro1[0].name="Deepak"
// // console.log(arro1);
// // console.log(arro2);


// //hack for above solution because it changes in both the array
// // var arro2=JSON.parse(JSON.stringify(arro1));
// // arro2[0].name="Deepak"
// // console.log(arro1);
// // console.log(arro2);


// // let arr=["A","B"]
// // // let com1= arr[0]
// // // let com2=arr[1]

// // let [com1,com2]= arr
// // console.log(com1);
// // console.log(com2);


// // let op1={
// //     title:"zero to hero",
// //     age:23,
// //     type:"!21"
// // }

// // let {title,age,type}= op1
// // console.log(title);

// // String interpolation- allow you add any another var in the string console output

// // var name="Sales"
// // var name1="Sal"
// // console.log('Hey '+name +'as' ); //wrong call

// // console.log(`my name is ${name}`);-- useful
// //string methods- str.include("hope")- return true or false  whether its available or not.
// //indexof - return first occurence--  str.indexOf("doing") 
// // startswith- str.startswith("hello")
// //slice= str.slice(start,end)
// //toLowerCase= str.toLowerCase() and toUpperCase
// //trim()- remove whitespaces from both side of  a string-- str.trim()


// //Object and Json operation
// //json.stringfy



// // let op1={
// //     title:"zero to hero",
// //     age:23,
// //     type:"!21"
// // }//Object keys
// // console.log(Object.keys(op1));
// // //object values
// // console.log(Object.values(op1));

// // // JSON.stringfy - convert obj into string 
// // let str= JSON.stringify(op1)
// // console.log(str)

// // // JSON parse - convert string into object -- JSON.parse(str)
// // console.log(JSON.parse(str));


//  //ARRAY METHODS

// let arr=[1,2,23,5,3,9]
// // map()
// // arr.methodName(function(currentItem,index,Actualarray)){

// // }
// let  arry= arr.map(function(currentItem,index,array){
//     console.log(`currentItem is ${currentItem} index ${index}, array ${array}`)
//     return currentItem*2

// })
// console.log(arr);
// console.log(arry);

// // filter
// let filteredValues= arr.filter(function(currentItem,index,array){
//     return currentItem>5
// })
// console.log(filteredValues)

// // every- check every element that every value is greater than 18
// let arr2=[32,33,18,40]
// let everyval=arr2.every(function(i){
//     return i>=18
// })
// console.log(everyval);


// // some--opposite of every
// let ar2=[32,33,18,40]
// let someval=ar2.some(function(i){
//     return i>=18
// })
// console.log(someval);


// // sort
// var names=["nikhil","aman","av"]
// console.log(names.sort());


// //sorting of a number
// var points=[1,2,3,12,4,5,121]
// let sortval=points.sort(function(a,b){
//     // return a-b - inn ascending
//     return b-a

// })
// console.log(sortval);


//reduce methods
// array.reduce(function(total,currentValue,index,array){

// },initialvalue)
let num=[12,78,30]
let sum=num.reduce(function(total,i){
    return total+i
},0)

console.log(sum);

// //foreach-- never return but map return
// num.forEach(function(i){
//     console.log(i);
// })

// Promise function
// function checkIsSuccess(data){
//     return new Promise(function(resolve, reject){
//         if(data==="success"){
//             return resolve("success")
//         } else {
//         return resolve("Fail")
//         }
//     })
// }
// checkIsSuccess('fail').then(function(result){
//     console.log(result);
// }).catch(function(error){
//     console.log(error)
// })

// fetch('git url').then(function(result){
//     // console.log(result);
//     return return.json()

// }).then(function(response){
//     console.log(response)
// })


//import and export modules - make sure module will be add in src under html file.

// import min, {PI,add} from './utils.js'
// import * as U from './utils.js'
// console.log(U.PI)
// console.log(U.add(3,1))
// console.log(U.min(12,1))


// let ele=document.querySelector('div')
// console.log(ele);
// ele.style.color="red"

// let eleall=document.querySelectorAll('div')
// console.log('eleall') 
// Arraxy.from(eleall).forEach(function(item){
//     item.style.color="green"
// })

// in lwc we use this.template.ele - that's the differnce

// // Events
// function Add1(a,b)
// {
//     console.log(a+b);
// }

// let btn=document.querySelector("button")
// btn.addEventListener("click",Add1);

// document.addEventListener("mousemove",handler)
// function handler(){
//     document.querySelector(".demo").innerHTML=Math.random()
// }

// function remove(){
//     document.removeEventListener("mousemove",handler)
// }
// console.log("hee");

// document.addEventListener("hello",function(data){
//     console.log("hello has called and send",  data.detail)
// })

// function callcustomMethod(){
//     let event= new CustomEvent("Hello", {
//         detail:{name:"nikhil"}
//     })
//     document.dispatchEvent(event);
// }

// Arrow Functions

// function abc(){
//     console.log("hello")
// }

//  const abc=()=>{
//     console.log("hello")
//  }

//  function sum(data){
//     let sum =data+10
//     return sum
//  }

//  const sum= (data1,data2)=>{
//     let sum=data1+data2+10
//     return sum
//  }
 
//  const sum= (data1,data2)=> data1+data2+10
//  console.log(sum(5,10));

//  var a=[1,2,3,4]
//  let new1=a.map((item)=>item*2)
//  console.log(new1)

// problem solved by arrow function

// let obj ={
//     name1:"nikhil",
//     getName:function(){
//         console.log(this.name1)
//         const fullname = ()=>{
//             console.log(this.name1)
//             console.log("my full name is "+this.name1+" karkra")
//         }
//         fullname()
//     }

// }
// obj.getName()


//  set timeout

let timerID= window.setTimeout(function(){
    console.log("hello")
},5000)



console.log(timerID)
clearTimeout(timerID)


// setinterval

let intervalId= window.setInterval(function(){
    console.log("hello")
},1000)

clearInterval(intervalId)









