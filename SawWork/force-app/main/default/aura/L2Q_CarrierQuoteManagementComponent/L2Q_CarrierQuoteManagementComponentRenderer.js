({
	afterRender: function (component, helper)
    {
        console.log('in after render, before component is valid');
        if (component.isValid())
        {
            this.superAfterRender();
            console.log('in after render, verified that component is valid');
            //Modified call to different method as part of SFDC-2870
            helper.createModal(component);
        }
    }
})