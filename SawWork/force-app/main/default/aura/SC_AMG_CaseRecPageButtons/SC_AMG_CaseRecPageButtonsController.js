({
    redirectToURL : function(component, event, helper)
    {
        console.log('In URL');
        
        var buttonLabel =  event.getSource().get("v.label");
        console.log('buttonLabel//'+buttonLabel);
        //window.open('https://collaborate.akamai.com/confluence/#all-updates');
        if(buttonLabel === 'Confluence')
        {
            
            console.log('In IF');
            window.open('https://collaborate.akamai.com/confluence/#all-updates');
        }
        if(buttonLabel == 'CRISP')
        {
            window.open('https://oracle-ebs.akamai.com/OA_HTML/OA.jsp?OAFunc=OAHOMEPAGE');
        }
        if(buttonLabel == 'Helpdesk')
        {
            window.open('https://ac.akamai.com/community/enterprise/helpdesk');
        }
        if(buttonLabel == 'Portal')
        {
            window.open('https://control.akamai.com');
        }
        if(buttonLabel == 'Siebel')
        {
            window.open('https://siebel.akamai.com/');
        }
        if(buttonLabel == 'PRISM')
        {
            window.open('https://prism.akamai.com/prism/');
        }
        if(buttonLabel == 'A360')
        {
            window.open('https://a360.akamai.com');
        }
    }
    
 })