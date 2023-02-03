({
	setThumbHelper : function(component,event) {
        var thumbs = [ 'like','dislike'];
        var values = { "like" : "1" , "dislike" : "0"};
        var thumbSelected = event.getSource().get("v.value")
        console.log(thumbSelected);
        
        thumbs.forEach(function(thumb){
            if(thumb === thumbSelected){
                 component.set("v.value",values[thumb]);
                 component.find(thumb).set("v.iconClass","glow");
               	 var temp = component.get("v.value");
                 console.log(temp);
            }
            else{
                 component.find(thumb).set("v.iconClass","");
            }
        });
       
	}
})