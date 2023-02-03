console.log('Before Snippet File');
embedded_svc.snippetSettingsFile.offlineSupportMinimizedText = 'Agents not available!';

window._snapinsSnippetSettingsFile = (function() {
    console.log("Snippet settings file loaded. 1");	// Logs that the snippet settings file was loaded successfully
    
    // embedded_svc.settings.extraPrechatFormDetails = [{
    //     "label": "First Name",
    //     "displayToAgent": false
    // }, {
    //     "label": "Last Name",
    //     "displayToAgent": false
    // }];
    embedded_svc.snippetSettingsFile.autoOpenPostChat = true;
    // embedded_svc.snippetSettingsFile.extraPrechatFormDetails = [{
    //     "label": "First Name",
    //     "value": "John",
    //     "displayToAgent": true
    //   }, {
    //     "label": "Last Name",
    //     "value": "Doe",
    //     "displayToAgent": true
    //   }, {
    //     "label": "Email",
    //     "value": "john.doe@salesforce.com",
    //     "displayToAgent": true
    //   }, {
    //     "label": "issue",
    //     "value": "Overriding your setup",
    //     "displayToAgent": true
    //   }];
    
    
    // embedded_svc.snippetSettingsFile.extraPrechatInfo = [{
    //     "entityName": "Case",
    //     "entityFieldMaps": [{
    //       "isExactMatch": false,
    //       "fieldName": "Subject",
    //       "doCreate": true,
    //       "doFind": false,
    //       "label": "shortDesc",
    //     },{
    //         "isExactMatch": false,
    //         "fieldName": "Description",
    //         "doCreate": true,
    //         "doFind": false,
    //         "label": "Description",
    //     }, {
    //       "isExactMatch": false,
    //       "fieldName": "Origin",
    //       "doCreate": true,
    //       "doFind": false,
    //       "label": "Origin",
    //       "value": "Community"
    //     }]
    //   }];
    // embedded_svc.settings.extraPrechatInfo = [{
    //     "entityName":"Case",
    //     "showOnCreate":true,
    //     "entityFieldMaps":[{"isExactMatch":false,"fieldName":"Business_Unit__c","doCreate":true,"doFind":false,"label":"Business Unit"}]
    // }];

    embedded_svc.snippetSettingsFile.extraPrechatFormDetails = [
                                                    { "label": "AccountId",
                                                        "transcriptFields": [
                                                            "AccountId"
                                                        ]
                                                    },
                                                    { "label": "ContactId",
                                                        "transcriptFields": [
                                                            "ContactId"
                                                        ]
                                                    },           
                                                    { "label": "CaseId",
                                                        "transcriptFields": [
                                                            "CaseId"
                                                        ]
                                                    },           
                                                    { "label": "AkamCaseId",
                                                        "transcriptFields": [
                                                            "Akam_Case_Id__c"
                                                        ]
                                                    },
                                                    { "label": "CaseOrigin",
                                                        "transcriptFields": [
                                                            "Case_Origin__c"
                                                        ]
                                                    },
                                                    { "label": "CasProduct",
                                                        "transcriptFields": [
                                                            "Case_Product__c"
                                                        ]
                                                    },
                                                    { "label": "CaseProductId",
                                                        "transcriptFields": [
                                                            "Case_Product_Id__c"
                                                        ]
                                                    },   
                                                    { "label": "CaseRequestType",
                                                        "transcriptFields": [
                                                            "Case_Request_Type__c"
                                                        ]
                                                    },   
                                                    { "label": "CaseService",
                                                        "transcriptFields": [
                                                            "Case_Service__c"
                                                        ]
                                                    },                                                                                                                                                            
                                                    { "label": "CaseVisibility",
                                                        "transcriptFields": [
                                                            "Case_Visibility__c"
                                                        ]
                                                    },                                                                                                                                                            
                                                    { "label": "Subject",
                                                        "transcriptFields": [
                                                            "Case_Subject__c"
                                                        ]
                                                    },
                                                    {   "label": "Description",
                                                        "transcriptFields": [
                                                            "Case_Description__c"
                                                        ]
                                                    },
                                                    {   "label": "RecordTypeId",
                                                        "transcriptFields": [
                                                            "Case_Record_Type__c"
                                                        ]
                                                    }
                                                    // 
                                                ];

    //     const buttonId = selRecType.label === 'Akatec' ? '5738B0000004C9N': '5738B0000004C9X';
    // embedded_svc.snippetSettingsFile.directToButtonRouting = function(prechatFormData) {
    //     console.log('prechatFormData ', prechatFormData);
    //     return  prechatFormData[8].value === '012G0000000z10x'?  '5738B0000004C9N': '5730f000000PX00';//'5738B0000004C9X';
    // }5738B0000004C9N
    
    embedded_svc.snippetSettingsFile.directToButtonRouting = function(prechatFormData) {
        console.log('prechatFormData ', prechatFormData);
        return window.jarvis_buttonid; //'5733F0000004F7s';// prechatFormData[8].value === '012G0000000z10x'?  '5730f000000PX05': '5730f000000PX05';// '5738B0000004C9X';//'5738B0000004C9X';
    }

    embedded_svc.snippetSettingsFile.offlineSupportMinimizedText = 'Agents not available!';
    document.addEventListener(
        "setCustomField",
        function(ev) {  
            window.jarvis_buttonid = ev.detail.chat.ButtonId;

            console.log('PreChat Event 12', ev);
            // embedded_svc.settings.extraPrechatFormDetails[0].value = 'Test Record Type';
            // Fire startChat callback.

            // embedded_svc.settings.extraPrechatFormDetails[0].value = event.detail.customField;

            embedded_svc.settings.extraPrechatFormDetails.forEach(el => {
                const val = ev.detail.case[el.label];
                if(val) {
                    el.value = val;
                }
            });

            // embedded_svc.snippetSettingsFile.directToButtonRouting = function(prechatFormData) {
            //     return ev.detail.chat.ButtonId;
            // }

            ev.detail.callback();
        },
        false
    );
    
    // embedded_svc.settings.extraPrechatFormDetails = [{
    //     "label": "First Name",
    //     "value": "John",
    //     "displayToAgent": true
    // }, {
    //     "label": "Last Name",
    //     "value": "Doe",
    //     "displayToAgent": true
    // }, {
    //     "label": "Email",
    //     "value": "john.doe@salesforce.com",
    //     "displayToAgent": true
    // }, {
    //     "label": "issue",
    //     "value": "Overriding your setup",
    //     "displayToAgent": true
    // }];
    
    // embedded_svc.settings.extraPrechatInfo = [{
    //     "entityName": "Contact",
    //     "showOnCreate": true,
    //     "linkToEntityName": "Case",
    //     "linkToEntityField": "ContactId",
    //     "saveToTranscript": "ContactId",
    //     "entityFieldMaps": [{
    //         "isExactMatch": true,
    //         "fieldName": "FirstName",
    //         "doCreate": true,
    //         "doFind": true,
    //         "label": "First Name"
    //     }, {
    //         "isExactMatch": true,
    //         "fieldName": "LastName",
    //         "doCreate": true,
    //         "doFind": true,
    //         "label": "Last Name"
    //     }, {
    //         "isExactMatch": true,
    //         "fieldName": "Email",
    //         "doCreate": true,
    //         "doFind": true,
    //         "label": "Email"
    //     }]
    // }, {
    //     "entityName": "Case",
    //     "showOnCreate": true,
    //     "saveToTranscript": "CaseId",
    //     "entityFieldMaps": [{
    //         "isExactMatch": false,
    //         "fieldName": "Description",
    //         "doCreate": true,
    //         "doFind": false,
    //         "label": "issue"
    //     }]
    // }]

    /*
    embedded_svc.snippetSettingsFile.avatarImgURL = 'https://yourwebsite.here/avatar.jpg';
    embedded_svc.snippetSettingsFile.smallCompanyLogoImgURL = 'https://yourwebsite.here/company_logo.png';
    embedded_svc.snippetSettingsFile.prechatBackgroundImgURL = 'https://yourwebsite.here/prechat_background.jpg';
    embedded_svc.snippetSettingsFile.waitingStateBackgroundImgURL = 'https://yourwebsite.here/waiting_background.png';
    embedded_svc.snippetSettingsFile.headerBackgroundURL = 'https://yourwebsite.here/header_background.jpg';
    embedded_svc.snippetSettingsFile.chatbotAvatarImgURL = 'https://yourwebsite.here/bot_avatar.jpg';
    embedded_svc.snippetSettingsFile.autoOpenPostChat = true;
    
    embedded_svc.snippetSettingsFile.externalScripts = ['my_scripts'];
    embedded_svc.snippetSettingsFile.externalStyles = ['my_styles'];
    
    embedded_svc.snippetSettingsFile.directToButtonRouting = function(prechatFormData) {
        if(prechatFormData[1].value === "Computer") {
            console.log("direct to button routing initiated.");
            alert("Alert: direct to button routing initiated!");
            return "BUTTONIDHERE";
        }
    }
    
    embedded_svc.snippetSettingsFile.fallbackRouting = ['USERIDHERE', 'BUTTONIDHERE', 'USERID_BUTTONID'];
    
    
    embedded_svc.snippetSettingsFile.extraPrechatFormDetails = [{"label":"FirstName","value":"John","displayToAgent":true},
                                                                {"label":"LastName","value":"Doe","displayToAgent":true},
                                                                {"label":"Email","value":"john.doe@salesforce.com","displayToAgent":true}];
    
    embedded_svc.snippetSettingsFile.extraPrechatInfo = [{
        "entityName": "Contact",
        "showOnCreate": true,
        "linkToEntityName": "Case",
        "linkToEntityField": "ContactId",
        "saveToTranscript": "ContactId",
        "entityFieldMaps" : [{
            "doCreate":true,
            "doFind":true,
            "fieldName":"FirstName",
            "isExactMatch":true,
            "label":"First Name"
        }, {
            "doCreate":true,
            "doFind":true,
            "fieldName":"LastName",
            "isExactMatch":true,
            "label":"Last Name"
        }, {
            "doCreate":true,
            "doFind":true,
            "fieldName":"Email",
            "isExactMatch":true,
            "label":"Email"
        }],
    }, {
        "entityName":"Case",
        "showOnCreate": true,
        "saveToTranscript": "CaseId",
        "entityFieldMaps": [{
            "isExactMatch": false,
            "fieldName": "Subject",
            "doCreate": true,
            "doFind": false,
            "label": "Issue"
        }, {
            "isExactMatch": false,
            "fieldName": "Status",
            "doCreate": true,
            "doFind": false,
            "label": "Status"
        }, {
            "isExactMatch": false,
            "fieldName": "Origin",
            "doCreate": true,
            "doFind": false,
            "label": "Origin"
        }]
    }];*/
})();