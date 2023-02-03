({
    
    ShowMessage : function(component,str,isError){
        var ct =  component.get('v.errorCount') +1;
        component.set('v.errorCount', ct);
     
        var text = document.createElement('div');
        text.id = 'errordiv_'+ct;
        text.className += 'fd_transit';
        text.innerHTML = str;
        text.style="opacity:1;transition: opacity 5s;";
        if(isError == false){
            text.style += "color:#04844b;";
        }
        var msgdiv = document.getElementById('msg_div');
        msgdiv.appendChild(text);
        this.fade(component,ct);
        
    }, 
 
    fade : function(component,ct) {
        console.log("Timeout 1  "+ct);
       setTimeout( this.fadeout_time, 2000,component,ct);
            
            
    },
    
    fadeout_time: function(component,ct){
       console.log("IN OUTER "+ct)
        var did = 'errordiv_'+ct;
        var el = document.getElementById(did);
        console.log(" elem "+el);
        el.style.opacity="0";
        console.log("DONE");
        
        setTimeout(function(did){
               console.log(" 2nd timeout "+did);
               var msgdiv = document.getElementById(did);
               msgdiv.style.display = "none";
           
            },5000,did);   
        
    },
    
    showNote : function(){
       var nd = document.getElementById('Note_Div');
        if(nd != null){
            nd.style="display:block";
        }
    }
	
})