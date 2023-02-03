({
	doInit : function(component, event, helper) {
        var tmzone = $A.get("$Locale.timezone");
       // var shortname =  moment().tz(tmzone).format('z');
        console.log('Timezone ');
        console.log(window.shorttimezone);
        component.set("v.userTimeZone",window.shorttimezone);
        
	}
})