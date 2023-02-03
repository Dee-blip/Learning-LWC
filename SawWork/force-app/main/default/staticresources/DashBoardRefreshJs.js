function refreshDashboard() {
	         var thebutton = document.getElementsByName('refresh') ; 
	thebutton.item(0).click();
	var refDiv=document.getElementById("Refeshdiv");
        refDiv.parentElement.parentNode.style.display = "none";
}
		
		
		 
if (window.addEventListener) // W3C standard
	{
	  window.addEventListener('load', refreshDashboard, false); // NB **not** 'onload'
	} 
else if (window.attachEvent) // Microsoft
	{
	  window.attachEvent('onload', refreshDashboard);
	}