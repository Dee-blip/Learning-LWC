({
    openGetStarted: function(component,event,helper) {
		//window.open("/customers/s/get-started/","_top");//Change the URL as per new community
        var urlToNav = component.get("v.button1URL");
        window.open(urlToNav,"_top");
    },
    openNews: function(component,event,helper) {
		//window.open("/customers/s/topic/0TO290000006KKiGAM/news-events/","_top");//Change the URL as per new community
   		var urlToNav = component.get("v.button2URL");
        window.open(urlToNav,"_top");
    },
})