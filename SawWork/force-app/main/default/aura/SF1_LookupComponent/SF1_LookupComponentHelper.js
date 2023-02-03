({
  //typeahead already initialized
  typeaheadInitStatus: {},
  //"old value" to trigger reload on "v.value" change
  typeaheadOldValue: {},
  //suggestione function returned after a successful match
  cb: null,
  outputHTMLsuggestion: '',
  /*
  	Creates the typeahead component using RequireJS, jQuery, Bootstrap and Bootstrap Typeahead
  */
  createTypeaheadComponent: function(component) {

    var self = this;
    var SObjectIcon = component.get("v.SObjectIcon");
    var fieldsToShowInSuggestion = component.get('v.fieldsToShowInSuggestion').split(',');
    var outputHTMLsuggestion = '<article class="slds-tile slds-tile_board slds-border_bottom">';
    outputHTMLsuggestion += '<div style="font-size:120%;padding-bottom:5px;" ><div class="slds-tile slds-media"><div class="slds-media__figure"><strong>';

    if (SObjectIcon == 'custom15') {
      outputHTMLsuggestion += '<span class="slds-icon_container slds-icon-custom-custom15">';
    } else {
      outputHTMLsuggestion += '<span class="slds-icon_container slds-icon-standard-' + SObjectIcon + '">';
    }

    outputHTMLsuggestion += '<svg class="slds-icon slds-icon--small" focusable="false" aria-hidden="true" data-key="' + SObjectIcon + '">';

    if (SObjectIcon == 'custom15') {
      outputHTMLsuggestion += '<use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="/_slds/icons/v7.31.0/custom-sprite/svg/symbols.svg#custom15"></use>';
    } else {
      outputHTMLsuggestion += '<use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="/_slds/icons/v7.31.0/standard-sprite/svg/symbols.svg#' + SObjectIcon + '"></use>';
    }

    outputHTMLsuggestion += '</svg></span></div>';
    outputHTMLsuggestion += '<div class="slds-media__body slds-truncate">{{value}}</strong>';
    for (let field in fieldsToShowInSuggestion) {
      outputHTMLsuggestion = outputHTMLsuggestion + ' {{sObj.' + fieldsToShowInSuggestion[field] + '}}';
      if (field == 0) {
        outputHTMLsuggestion += '<br />';
      } else {
        outputHTMLsuggestion += '&nbsp;&nbsp;'
      }
    }
    outputHTMLsuggestion = outputHTMLsuggestion + '</div></div></article>';
    var globalId = component.getGlobalId();
    //loading libraries sequentially
    var inputElement = jQuery('[id="' + globalId + '_typeahead"]');
    //init the input element
    inputElement.val(component.get("v.nameValue"));

    //handles the change function
    inputElement.keyup(function() {
      if (inputElement.val() !== component.get('v.nameValue')) {
        component.set('v.nameValue', inputElement.val());
        component.set('v.value', null);
        component.set('v.valueSObject', null);
        //self.typeaheadOldValue[component.getGlobalId()] = null;
      }
    });

    //inits the typeahead
    inputElement.typeahead({
        hint: false,
        highlight: true,
        minLength: 1
      }, {
        name: 'objects',
        displayKey: 'value',
        source: function(q, cb) {
          self.cb = cb;
          // Changes for MOB-262

          // remove last space
          if ((q.lastIndexOf(' ') + 1) == q.length) {
            q = q.substring(0, q.length - 1);
          }
          // end of changes for MOB-262

          q = (q || '').replace(/[-[\]{}\/()*+&?.^$|]/g, "\\$&");
          var compEvent = component.getEvent("SF1_InputLookupEvent");
          compEvent.setParams({
            "searchString": q
          });
          compEvent.fire();
        },
        templates: {
          empty: [
            '<div class="empty-message">',
            'No match found',
            '</div>'
          ].join('\n'),
          suggestion: Handlebars.compile(outputHTMLsuggestion)
        }
      })
      //selects the element
      .bind('typeahead:selected',
        function(evnt, suggestion) {
          console.log('suggestion :', JSON.stringify(suggestion));
          component.set('v.value', suggestion.sObj.Id);
          component.set('v.valueSObject', suggestion.sObj);
          component.set('v.nameValue', suggestion.value);
        });

  },

  /*
   * Searches objects (server call)
   */
  searchAction: function(component, q) {
    if (!component.isValid()) return;

    var self = this;
    var action = component.get("c.searchSObject");
    action.setParams({
      'type': component.get('v.type'),
      'searchString': q,
      'fieldsToShowInSuggestion': component.get('v.fieldsToShowInSuggestion'),
      'whereClause': component.get('v.whereClause')
    });

    action.setCallback(this, function(a) {
      if (a.error && a.error.length) {
        return $A.error('Unexpected error: ' + a.error[0].message);
      }
      var result = a.getReturnValue();
      var matches, substrRegex;

      // an array that will be populated with substring matches
      var matches = [];

      // regex used to determine if a string contains the substring `q`
      var substrRegex = new RegExp(q, 'i');
      var strs = JSON.parse(result);

      // iterate through the pool of strings and for any string that
      // contains the substring `q`, add it to the `matches` array
      jQuery.each(strs, function(i, str) {
        if (substrRegex.test(str.value)) {
          // the typeahead jQuery plugin expects suggestions to a
          // JavaScript object, refer to typeahead docs for more info
          matches.push({
            value: str.value,
            sObj: str.sobjt
          });
        }
      });
      if (!strs || !strs.length) {
        component.set('v.value', null);
      }
      self.cb(matches);
    });
    $A.enqueueAction(action);
  },


  /*
   * Method used on initialization to get the "name" value of the lookup
   */
  loadFirstValue: function(component) {

    //this is necessary to avoid multiple initializations (same event fired again and again)
    if (this.typeaheadInitStatus[component.getGlobalId()]) {
      return;
    }

    this.typeaheadInitStatus[component.getGlobalId()] = true;
    this.loadValue(component);

  },

  setSObjectIcon: function(component) {
    var sObjectType = component.get("v.type");
    var sObjectIcon = 'custom15';

    if (sObjectType == 'Account') {
      sObjectIcon = 'account';
    } else if (sObjectType == 'Campaign') {
      sObjectIcon = 'campaign';
    } else if (sObjectType == 'Contact') {
      sObjectIcon = 'contact';
    } else if (sObjectType == 'Contract') {
      sObjectIcon = 'contract';
    } else if (sObjectType == 'Opportunity') {
      sObjectIcon = 'opportunity';
    } else if (sObjectType == 'Product') {
      sObjectIcon = 'product';
    } else if (sObjectType == 'User') {
      sObjectIcon = 'user';
    }

    component.set("v.SObjectIcon", sObjectIcon);
  },

  /*
   * Method used to load the initial value of the typeahead
   * (used both on initialization and when the "v.value" is changed)
   */
  loadValue: function(component, skipTypeaheadLoading) {
    this.typeaheadOldValue[component.getGlobalId()] = component.get('v.value');

    var action = component.get("c.getCurrentValue");
    var self = this;
    action.setParams({
      'type': component.get('v.type'),
      'value': component.get('v.value'),
    });

    action.setCallback(this, function(a) {
      if (a.error && a.error.length) {
        return $A.error('Unexpected error: ' + a.error[0].message);
      }
      var result = a.getReturnValue();
      var globalId = component.getGlobalId();
      component.set('v.isLoading', false);
      component.set('v.nameValue', result || '');
      if (result) jQuery('[id="' + globalId + '_typeahead"]').val(result || '');
      if (!skipTypeaheadLoading) self.createTypeaheadComponent(component);

    });
    $A.enqueueAction(action);

  }
})