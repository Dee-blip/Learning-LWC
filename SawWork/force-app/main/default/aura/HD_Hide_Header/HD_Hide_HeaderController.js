({
    hideHeader : function(component, event, helper) {
        var up = component.find("iconup");
        var down =  component.find("icondown");
        
        //console.log(up);
        $A.util.addClass(up, 'hideHeader');
        
        var getHeaderonpure = document.getElementById("oneHeader");        
        //console.log('--->'+getHeaderone+' --> '+getHeaderonpure);
        if (getHeaderonpure != null)
        {
            getHeaderonpure.style.display = "none"; 
            var sec = document.getElementsByTagName('section')[0];
            sec.style.top = "0px";
            // console.log(" --> "+sec);
        }
        
        //code for handling detailed header data 
        //
        // var headerElem = document.getElementsByTagName("header")[0];
        //     console.log('Header info ---> '+ headerElem );
        helper.DisplayIntroButton(component);//finding weather to enable intro Droapdown Button     
        helper.IntroConfiguratorHelper(component);//getting configuration data from custom settings
    },
    showHeader : function(component){
        var up = component.find("iconup");
        var down =  component.find("icondown");
        
        var getHeaderonpure = document.getElementById("oneHeader");        
        //console.log('--->'+getHeaderone+' --> '+getHeaderonpure);
        if (getHeaderonpure != null)
        {
            if( $A.util.hasClass(up,"hideHeader"))
            {
                console.log($A.util.hasClass(up,"hideHeader"));
                getHeaderonpure.style.display = ""; 
                var sec = document.getElementsByTagName('section')[0];
                sec.style.top = "133px";
                // console.log(" --> "+sec);
                $A.util.addClass(down, 'hideHeader');
                $A.util.removeClass(up, 'hideHeader');
                
                
            }// if( $A.util.addClass(up,"hideHeader") )
            else
            {
                
                getHeaderonpure.style.display = "none"; 
                var sec = document.getElementsByTagName('section')[0];
                sec.style.top = "0px";
                // console.log(" --> "+sec);
                $A.util.removeClass(down, 'hideHeader');
                $A.util.addClass(up, 'hideHeader');
                
            }//else
            
            
        }//if(getHeaderonpure != null)
    },
    toggleAppSpinner: function (cmp, event) {
        var spinner = cmp.find("applevelspinner");
        $A.util.toggleClass(spinner, "slds-hide");
    },
    introStarter: function(cmp,event,helper){
        helper.IntroConfiguratorHelper(cmp);
        helper.showWalkthroughtIntroHelper(cmp);
    },
    hideWalkthroughtIntro: function(cmp,event,helper)
    {
        helper.hideWalkthroughtIntroHelper(cmp);
    },
    startWalkThrought: function(cmp,event,helper)
    {   
        //helper.IntroConfiguratorHelper(cmp);//getting configuration data from custom settings
        helper.hideWalkthroughtIntroHelper(cmp);
        helper.StartIntroHelper(cmp);
    },
    toggleMenu: function(cmp,event) // function for invoke dropdown
    {
        var helpmenu = cmp.find('helpmenu');
        if(helpmenu != null)
        {
            $A.util.toggleClass(helpmenu,'slds-dropdown-trigger_click');
        }
        
    },

})