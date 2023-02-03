var outputFromCgi = "Error: No Captcha Found";

function GetXmlHttpObject()
{

  var xmlHttp = null;
  try { //Firefox, Opera 8.0+, Safari
    xmlHttp =  new XMLHttpRequest();
  } catch(e) {
    try { //Internet Explorer
      xmlHttp =  new ActiveXObject("Msxml2.XMLHTTP");
    } catch (e) {
      try {
        xmlHttp =  new ActiveXObject("Microsoft.XMLHTTP");
      } catch (e) {
        if ( !GetXmlHttpObject.failedDetection ) {
          alert("Your browser does not support AJAX.");
          GetXmlHttpObject.failedDetection = true;
        }
      }
    }
  }
  return xmlHttp;
}
/******************************************************/
function stateChanged(funcs, xmlHttpObject){

   if (xmlHttpObject.readyState == 4 && xmlHttpObject.status == 200) {

      outputFromCgi = xmlHttpObject.responseText; //output varies on invoking function

                          //any custom code that needs to be run gets done here
                          // funcs contains custom code to execute after the desired readyState is complete

      if (funcs != "") { eval( funcs ); }
   } 

   return false;
}
/******************************************************/
function callCgi(url,codeToRun){

   xmlHttp = GetXmlHttpObject();
   //xmlHttp.failedDetection = false;

   if (xmlHttp == null) { alert("Your browser does not support Ajax"); return; }

/*
   xmlHttp.onreadystatechange = function(){
                                     if (xmlHttp.readyState == 4)
                                     if (xmlHttp.status == 200)
                                     stateChanged(codeToRun, xmlHttp);
                                }

 
 

   //original code  
   xmlHttp.open("GET",url,true);
   xmlHttp.send(null);
 */ 



   xmlHttp.open("GET",url,false);
   xmlHttp.send(null);

   outputFromCgi = xmlHttp.responseText;

   eval ( codeToRun );

}
/******************************************************/
function insertOptions(){

   var url       = "/cgi/rod/rodOptionList.cgi"; 
   var timeStamp = "ms="+new Date().getTime();  //timestamp for IE caching bug
   var fullUrl   = url + "?" + timeStamp;

   //outputFromCgi here contains the html that creates the captcha image
   var runWhenAjaxComplete = "document.getElementById('spoof').innerHTML = outputFromCgi";

   callCgi(fullUrl,runWhenAjaxComplete);
}
/******************************************************/



/******************************************************/
function getPubUserAjax(){

   var url       = "/cgi/rod/getPubUser.cgi";
   var timeStamp = "ms="+new Date().getTime();  //timestamp for IE caching bug
   var fullUrl   = url + "?" + timeStamp;

   //outputFromCgi here contains the html that creates the captcha image
   var runWhenAjaxComplete = "pubName = outputFromCgi;";

   callCgi(fullUrl,runWhenAjaxComplete);
}
/******************************************************/



/******************************************************/
function isPubUserAdminAjax(){

   var url       = "/cgi/rod/isPubUserAdmin.cgi";
   var timeStamp = "ms="+new Date().getTime();  //timestamp for IE caching bug
   var fullUrl   = url + "?" + timeStamp;

   //outputFromCgi here contains the html that creates the captcha image
   var runWhenAjaxComplete = "if ( outputFromCgi == 1 ) { isPubUserAdmin = 1;}";

   callCgi(fullUrl,runWhenAjaxComplete);
}
/******************************************************/



/******************************************************/
function getUserTypeAjax(name){

   var url       = "/cgi/rod/getUserType.cgi";
   var timeStamp = "ms="+new Date().getTime();  //timestamp for IE caching bug
   var idStr     = "id="+name;  
   var fullUrl   = url + "?" + timeStamp + "&" + idStr;

   //outputFromCgi here contains the html that creates the captcha image
   var runWhenAjaxComplete = "userType = outputFromCgi;";
   
   callCgi(fullUrl,runWhenAjaxComplete);
}
/******************************************************/



   
