({
    unrender: function (component) {
        console.log('unrender');
        this.superUnrender(); 
         component.destroy();
    },

})