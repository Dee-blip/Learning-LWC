


function resizeFrame() {
	         var id= document.getElementById("loading");
		     id.parentElement.parentNode.childNodes[0].childNodes[0].style.display = "none";
			 var parentIFrame = document.getElementById('JSControl');
			 parentIFrame.style.display="block";
			 var pageURL = document.location.href
			 
			 var spliturl=pageURL.match("/home/home.jsp");
			 
			 
	        if(spliturl != "null" && spliturl == "/home/home.jsp")		 
				{ 
			
					if ( parentIFrame != null ) {
			    
                
					sforce.connection.sessionId=getCookie('sid');
					result = sforce.apex.execute("VF_HomepageController","BillboardControl",{});
				    document.getElementById("loading").style.display="none";
					
					var result = result + "";
			
					if(result == "") 
						{		   
							parentIFrame.style.display="none";
							id.parentElement.parentNode.style.display="none";
						}
					if (result != "")
						{
							var splitresult=new Array();
							splitresult=result.split(":",4);
							var height = splitresult[0];
							var height_unit=splitresult[1];
							var width  = splitresult[2];
							var width_unit = splitresult[3];
				
					parentIFrame.height =  height+height_unit;
					parentIFrame.width  =  width+width_unit;
					parentIFrame.style.display="visible";
						}					
					}  
				 
				}
			}
		
		
		 
if (window.addEventListener) // W3C standard
	{
	  window.addEventListener('load', resizeFrame, false); // NB **not** 'onload'
	} 
else if (window.attachEvent) // Microsoft
	{
	  window.attachEvent('onload', resizeFrame);
	}

