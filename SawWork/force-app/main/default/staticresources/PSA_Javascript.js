        $j = jQuery.noConflict();
        
        function uncheckOthers(leaveChecked) {
          var checkboxes = new Array(); 
          checkboxes = document.getElementsByTagName('input');
         
          for (var i=0; i<checkboxes.length; i++)  {
            if (checkboxes[i].type == 'checkbox') {
                if (checkboxes[i] != leaveChecked) {
                    checkboxes[i].checked = false;
                }
             }
          } 
        }
              
        function switchExpandImage(obj,obj1,obj2) 
        {
            var el = document.getElementById(obj);                                 
            if ( el.style.display != 'none' ) {
                el.style.display = 'none';
            } else {
                el.style.display = '';
            }
            
            var e2 = document.getElementById(obj1);                                
            if ( e2.style.display != 'none' ) {   
            e2.style.display = 'none';
            }
            else {
            e2.style.display = '';
            }
             var e3 = document.getElementById(obj2);                                       
            if ( e2.style.display != 'none' ) {
            e3.style.display = 'none';
            }
            else {
            e3.style.display = '';
            }
        }  
        
       function expandAll() {
           var elements = document.getElementsByTagName('div');
           for (var i=0; i<elements.length; i++) {
              var elem = elements[i];
              var elemClass = elem.getAttribute("class");
              if (elemClass != null) {
                if (elemClass.indexOf("inlineTbl") !=-1) {
                    elem.style.display = '';
                } else if (elemClass.indexOf("plusImage") !=-1) {
                    elem.style.display = 'none';
                } else if (elemClass.indexOf("minusImage") !=-1) {
                    elem.style.display = '';      
                }        
              } 
           }     
           
           var elements = document.getElementsByTagName('input');
           for (var i=0; i<elements.length; i++) {
              var elem = elements[i];
              var elemClass = elem.getAttribute("class");
              if (elemClass != null) {
                if (elemClass.indexOf("expandBtnTop") !=-1) {
                    elem.disabled=true;
                } else if (elemClass.indexOf("expandBtnBot") !=-1) {
                    elem.disabled=true;
                } else if (elemClass.indexOf("collapseBtnTop") !=-1) {
                    elem.disabled=false;
                } else if (elemClass.indexOf("collapseBtnBot") !=-1) {
                    elem.disabled=false;
                } 
              } 
           }     
       }
       
       function collapseAll() {
           var elements = document.getElementsByTagName('div');
           for (var i=0; i<elements.length; i++) {
              var elem = elements[i];
              var elemClass = elem.getAttribute("class");
              if (elemClass != null) {
                if (elemClass.indexOf("inlineTbl") !=-1) {
                    elem.style.display = 'none';
                } else if (elemClass.indexOf("plusImage") !=-1) {
                    elem.style.display = '';
                } else if (elemClass.indexOf("minusImage") !=-1) {
                    elem.style.display = 'none';    
                }        
              } 
           }     
           
           var elements = document.getElementsByTagName('input');
           for (var i=0; i<elements.length; i++) {
              var elem = elements[i];
              var elemClass = elem.getAttribute("class");
              if (elemClass != null) {
                if (elemClass.indexOf("collapseBtnTop") !=-1) {
                    elem.disabled=true;
                } else if (elemClass.indexOf("collapseBtnBot") !=-1) {
                    elem.disabled=true;
                } else if (elemClass.indexOf("expandBtnTop") !=-1) {
                    elem.disabled=false;
                } else if (elemClass.indexOf("expandBtnBot") !=-1) {
                    elem.disabled=false;
                } 
              } 
           }     
       }
       
       
        var isDirty = false;
        var msg = 'You have not saved your changes.  Please click Save or Cancel';
        
        function saveJS() {
            isDirty = false;
            saveChanges();
        }
        
        function cancelJS() {
            isDirty = false;
            cancelChanges();
        }
        
        function filterJS() {
            if (isDirty) {
                alert(msg);
            } else {
                filter();
            }   
        }
        
        function clearJS() {
            if (isDirty) {
                alert(msg);
            } else {
                clear();
            }   
        }
        
        $j(document).ready(function(){
            
           $j('#saveBtnTop').prop('disabled',true);
           $j('#cancelBtnTop').prop('disabled',true);
           $j('#saveBtnBot').prop('disabled',true);
           $j('#cancelBtnBot').prop('disabled',true);   
         
           $j('input').not('.ignoredirty').keyup( function() {
              if(!isDirty){  
                 isDirty = true;
                 $j('#saveBtnTop').prop('disabled',false);
                 $j('#cancelBtnTop').prop('disabled',false);
                 $j('#saveBtnBot').prop('disabled',false);
                 $j('#cancelBtnBot').prop('disabled',false);
              }
           });
           
            $j('input').not('.ignoredirty').change( function() {
              if(!isDirty){  
                 isDirty = true;
                 $j('#saveBtnTop').prop('disabled',false);
                 $j('#cancelBtnTop').prop('disabled',false);
                 $j('#saveBtnBot').prop('disabled',false);
                 $j('#cancelBtnBot').prop('disabled',false);
              }
           });
           
            $j('textarea').keyup( function() {
              if(!isDirty){  
                 isDirty = true;
                 $j('#saveBtnTop').prop('disabled',false);
                 $j('#cancelBtnTop').prop('disabled',false);
                 $j('#saveBtnBot').prop('disabled',false);
                 $j('#cancelBtnBot').prop('disabled',false);
              }
           });
           
           $j('select').not('.ignoredirty').keyup( function() {
              if(!isDirty){  
                 isDirty = true;
                 $j('#saveBtnTop').prop('disabled',false);
                 $j('#cancelBtnTop').prop('disabled',false);
                 $j('#saveBtnBot').prop('disabled',false);
                 $j('#cancelBtnBot').prop('disabled',false);
              }
           });
        
           $j('form').submit(function() {
                isDirty = false;
                return true;
            });
            
           $j('#expandBtn').click(function(){
                alert('expand clicked');
           });
            
           window.onbeforeunload = function(){
              if(isDirty) {
                 return msg;
              }
           };
        });