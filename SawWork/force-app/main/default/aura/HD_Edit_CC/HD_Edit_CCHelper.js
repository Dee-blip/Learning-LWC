({
    waiting: function(component) {
        var ele = component.find("Accspinner");
        console.log(ele);
        $A.util.addClass(ele,"slds-show");
        $A.util.removeClass(ele,"slds-hide");
        //document.getElementById("Accspinner").style.display = "block";
     },
     
      doneWaiting: function(component) {
            var ele = component.find("Accspinner");
            $A.util.addClass(ele,"slds-hide");
            $A.util.removeClass(ele,"slds-show");
     },
    
    addCCtextbox : function(component,value) {

        var ct = component.get("v.id_count");
        var fld_nos = document.querySelectorAll('#ccdiv_11 .ccbox').length;
        if(fld_nos == 10){
            component.set("v.warnings",'Maximum 10 CC emails are allowed');
            return;
        }
 
        var addList = document.getElementById('ccdiv_11');
        var docstyle = addList.style.display;
        if (docstyle == 'none') addList.style.display = '';
      
        
        ct = ct + 1 ;
        var nct = ct.toString();
        
        
        var text = document.createElement('span');
        text.id = 'cc_row_'+nct;
        text.className = 'ccbox ccadded';
        var txtid = 'cc_txtfield_'+nct;
        var arid =  'ar_cc_txtfield_'+ct;
        var spid = "ccclose_"+nct;
        var butnspan = 'btnspn_'+nct;
         
        var htmltxt = "<br/><input type='text' size='30' id='"+txtid+"' aura:id='"+arid+"' placeholder='example@akamai.com'/>";
        htmltxt += "&nbsp;&nbsp;<button id='"+spid+"' aura:id='ar_abcd' class='slds-button slds-button_neutral slds-button_small sldsbtn-style'  > <b>-</b> </button>"
        
        text.innerHTML = htmltxt;
        addList.appendChild(text);
        
        var el = document.getElementById("ccclose_"+nct);
        var ccbx = document.getElementById(txtid);
        ccbx.className = 'cc_input';
        if(value.trim() != ''){
           
           ccbx.value = value;
           
        }

        var cls_el = document.getElementById(spid);
        cls_el.onclick = function(){ 
                                      var fg = document.getElementById("cc_row_"+nct);
                                      var elems =  document.querySelectorAll('#ccdiv_11 .ccbox');
                                      var infld ;
                                      var el;
                                      if(elems.length == 1){
                                          document.getElementById("cc_txtfield_"+nct).value = '';
                                          return ;
                                      }
                   
                                      fg.classList.remove("ccbox");
                                      elems =  document.querySelectorAll('#ccdiv_11 .ccbox');
                                      el = elems[elems.length - 1] ;
                      
                                      el.appendChild(document.getElementById('cc_btn_spn'));                      
                                      var infld = document.getElementById("cc_txtfield_"+nct);
                                     
                                      infld.classList.remove("cc_input");
                                      console.log(infld.classList);                         
                                      fg.style = "display:none";
                                      var btn = component.find("upbtn");
                                      btn.set("v.disabled",false); 
                                    
                                      var ccList = component.get("v.ccList");
                                      var txt_fldid = "cc_txtfield_"+nct;
                                      var ccval = document.getElementById(txt_fldid).value;
                                      var incident_cctext = []
                                   
                                      for(var i =0; i < ccList.length; i++  ){
                                          
                                          if (ccval != ccList[i]){
                                              incident_cctext.push(ccval);
                                          }
                                      }      
          
          };
        document.getElementById(txtid).onkeydown  = function(){
            var btn = component.find("upbtn");
            btn.set("v.disabled",false);
        };

        var sp_el = document.createElement('span');
        sp_el.id = 'btnspn_'+nct;
        sp_el.className += 'btn_spn';
        var pr = document.getElementById('cc_row_'+nct);
        pr.appendChild(sp_el);
        
        var bts = document.getElementById(butnspan);
        bts.appendChild(document.getElementById('cc_btn_spn'));
        component.set("v.id_count",ct);
    },
   
    
    joinUpdateCC: function(component){
        
        var allCC = document.getElementsByClassName('cc_input');
        console.log(' Logging Updates --');
        console.log(allCC.length);
        
        if (allCC.length == 0){
            component.set("v.cctext", ccemail);
            return '';
        }
      
       // var rex = /^[A-Za-z0-9._%+-]+@akamai.com$/igm;  
        var rex = /^[a-zA-Z0-9_]+[-a-zA-Z0-9-_.]+@akamai.com$/igm;
        var errmsg = '';
        var ccstr = [];
         
        for( var i =0 ; i < allCC.length; i++){
            var s = allCC[i].value.trim();
            if ( s != ''){
                if ( s.match(rex) == null ){
                    errmsg += s;
                    break;
                }
                ccstr.push(s);
            }    
             
                
            
        }
       
        
        if (errmsg != ''){
            return  errmsg;
        }
        else{
           var ccemail = ccstr.join(',');
           var scc = component.get("v.savedcc");
           component.set("v.cctext", ccemail); 
           if(scc.trim() == ccemail){
               return ' Or add/modify email address'
           }
           
           return ''; 
        }
    },

    
    removeCCtxt : function(component,event,id){
        var spid = "cc_row_"+id;
        var iptxtid = "cc_txtfield_"+id;
        console.log(' in '+iptxtid);
        var ccval = document.getElementById(iptxtid).value.trim();
        
        console.log('  -- -- '+ccval);
        var cctxt =  component.get("v.savedcc");
        console.log(' 1 -- -- '+cctxt);
        var elems =  document.querySelectorAll('#ccdiv_11 .cc_input');
        console.log("ELMS SIZE "+elems.length);
        if(cctxt.trim() == ''){
            if (elems.length == 1){
                elems[0].value = '';
            }else{
                var addList = document.getElementById(spid);
                addList.classList.remove("ccbox");
                var rmelem = document.getElementById(iptxtid);
                rmelem.classList.remove("cc_input");
                addList.removeChild(rmelem);
                addList.style = "display:none";
                
            }
            return '';
        }
        cctxt = cctxt.replace(/;/g, ',').replace(/,\s*$/, "");
        var cctxt_arr = cctxt.split(",");
        var updatecc = [];
        for (var i = 0; i < cctxt_arr.length; i++){
            if ( cctxt_arr[i] != ccval ){
               updatecc.push(cctxt_arr[i]);
            }
        }
        console.log('  Update '+updatecc.join(';'));
        return updatecc.join(';');
    },
    
    hideDiv :  function(component,event,id){
        var spid = "cc_row_"+id;
        var iptxtid = "cc_txtfield_"+id;
        console.log(' in hide '+iptxtid);
        console.log(document.getElementById(iptxtid));
        var elems =  document.querySelectorAll('#ccdiv_11 .ccbox');
        if(elems.length == 1){
            document.getElementById(iptxtid).value = '';
            return;
        } 
        document.getElementById(spid).classList.remove("ccbox");
        elems =  document.querySelectorAll('#ccdiv_11 .ccbox');
        var el = elems[elems.length -1];
        el.appendChild(document.getElementById('cc_btn_spn'));                         
        document.getElementById(iptxtid).classList.remove("cc_input");
        document.getElementById(spid).style.display = 'none';
        
    },
    
    setCCtxt : function(component,event,ccstr){
        var cc_arr = [];
        var elems =  document.querySelectorAll('#ccdiv_11 .ccbox');
        console.log(" ABCDEE -- "+ccstr)
        if(ccstr != null && ccstr.trim() != ''){
               ccstr =  ccstr.replace(/;/g, ',').replace(/,\s*$/, "");

               component.set("v.savedcc",ccstr);
               
               cc_arr = ccstr.split(',');
                
               }else{
                   component.set("v.savedcc",'');
                   cc_arr[0] = '';
                   
                 
                   
               }   
            console.log("CC arr "+cc_arr);
            console.log("CC arr lng  "+cc_arr.length);
            component.set("v.ccList",cc_arr);
             console.log("CC arr lng 222 "+cc_arr.length);
            component.set("v.cc_count",cc_arr.length);
            component.set("v.id_count",cc_arr.length - 1);
    },
    
    removeallnodes : function(){
        const elements = document.getElementsByClassName("ccadded");
        while (elements.length > 0) { elements[0].remove(); }      
   }

    
})