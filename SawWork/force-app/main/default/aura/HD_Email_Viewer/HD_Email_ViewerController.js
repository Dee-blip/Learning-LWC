({
	trimAction : function(component, event, helper) {
	var rawEmail = component.get('v.emailContent');
    //console.log('RawEmail ---> '+rawEmail);
    var trimmedMail = rawEmail.match(/^(From :)+([\W\w]*?)(From:)/gm);
    if(trimmedMail && trimmedMail.length > 0)
    {
      component.set('v.hasMore',true);
      component.set('v.trimmedcontent',trimmedMail[0]);
    }
     else
        {
          component.set('v.trimmedcontent',rawEmail);  
        }
        
      
	},
    
    showMoreAction: function(component, event, helper){
        
     var rawEmail = component.get('v.emailContent');
     component.set('v.trimmedcontent',rawEmail); 
     component.set('v.hasMore',false);
        
    }
    
    
})