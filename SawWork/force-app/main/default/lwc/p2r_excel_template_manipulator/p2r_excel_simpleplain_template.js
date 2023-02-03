/*
Developer @ Hemant Barapatre
purpose: To generate the excel on the fly on the LWC component
Template: for Compnent P2r_excel_template_manipulator

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 29/08/2020

Base Line : Used as a part of dynamic Excel Generation feature for CPQ/HD, for gettig the template metadata

Purpose : To get the template structur for Excel component

Usage : used as an implementation for P2r_excel_template_manipulator.

component Associated : [ P2r_excel_template_manipulator ]

Class used : P2r_Excel_Template_Manipulator

*/
export const p2r_excel_simpleplain_template = () => {
    return {
        TEMPLATE_NAME: 'Simple_Plain',
        THUMBNAIL: '',
        TARGET_MAP: {
            STATIC_AREA: [
                //    { TARGET_CELL: "1", TARGET_VALUE: "Akamai Technologies India Pvt Ltd.", TYPE: "static" },
                {
                    TARGET_CELL: 'B1',
                    TARGET_VALUE: 'Name',
                    TYPE: 'dynamic',
                    STYLE: {
                        bold: true
                    }
                }, {
                    TARGET_CELL: 'B3',
                    TARGET_VALUE: 'Prepared_For_End_User__c',
                    TYPE: 'dynamic',
                    
                }, {
                    TARGET_CELL: 'B4',
                    TARGET_VALUE: 'Opportunity_Reseller__c',
                    TYPE: 'dynamic',
                    
                }, 
                {
                    TARGET_CELL: 'B5',
                    TARGET_VALUE: 'Reseller_Akamai_Acct_ID__c',
                    TYPE: 'dynamic',
                    
                }, 
                {
                    TARGET_CELL: 'B6',
                    TARGET_VALUE: 'SBQQ__SalesRep__r',
                    TYPE: 'dynamic',
                    
                }, {
                    TARGET_CELL: 'B7',
                    TARGET_VALUE: 'CurrencyIsoCode',
                    TYPE: 'dynamic',
                    
                    
                }, {
                    TARGET_CELL: 'B8',
                    TARGET_VALUE: 'CPQ_Order_Placed__c',
                    TYPE: 'dynamic',
                    
                }, {
                    TARGET_CELL: 'D3',
                    TARGET_VALUE: 'CPQ_Quote_Type_Label__c',
                    TYPE: 'dynamic',
                    
                }, {
                    TARGET_CELL: 'D4',
                    TARGET_VALUE: 'CPQ_Biliing_Effective_Date__c',
                    TYPE: 'dynamic',
                    
                }, {
                    TARGET_CELL: 'D5',
                    TARGET_VALUE: 'SBQQ__EndDate__c',
                    TYPE: 'dynamic',
                    
                }, {
                    TARGET_CELL: 'D6',
                    TARGET_VALUE: 'SBQQ__ExpirationDate__c',
                    TYPE: 'dynamic',
                    
                }, {
                    TARGET_CELL: 'D7',
                    TARGET_VALUE: 'CPQ_Integration_Type__c',
                    TYPE: 'dynamic',
                    
                }, {
                    TARGET_CELL: 'D8',
                    TARGET_VALUE: 'Akamai Technologies, Inc',
                    TYPE: 'static',
                    
                }, {
                    TARGET_CELL: 'B10',
                    TARGET_VALUE: 'SBQQ__NetAmount__c',
                    TYPE: 'dynamic',
                    STYLE: {
                        bold: true,
                        numberFormat: "0.00",
                    }
                },
                {
                    TARGET_CELL: 'C1',
                    TARGET_VALUE: 'Draft_water_mark__c',
                    TYPE: 'dynamic',
                    STYLE: {
                        bold: true,
                        fontSize: 20,
                    }
                },

            ],
            ITERATIVE_AREA: [{
                columns: {
                    A: {
                        key: 'name',
                        style: {
                            bold: false,
                            italic: false
                            
                        },
                        showTotal: false
                    },
                    B: {
                        key: 'quantity',
                        style: {
                            bold: false,
                            italic: false
                        },
                        showTotal: false
                    },
                    C: {
                        key: 'rateSuffix',
                        style: {
                            bold: false,
                            italic: false
                        },
                        showTotal: false
                    },
                    D: {
                        key: 'netPrice',
                        style: {
                            numberFormat: "0.00"
                        },
                        showTotal: false
                    },
                    E: {
                        key: 'billingFrequency',
                        style: {
                            bold: false,
                            italic: false
                        },
                        showTotal: false
                    },
                    F: {
                        key: 'billingModel',
                        style: {
                            bold: false,
                            italic: false
                        },
                        showTotal: false
                    },
                    G: {
                        key: 'overageRate',
                        style: {
                            numberFormat: "0.00"
                        },
                        showTotal: false
                    },
                    H: {
                        key: 'netTotal',
                        style: {
                            numberFormat: "0.00"
                        },
                        showTotal: true
                    },
                    I: {
                        key: 'oneTimeFee',
                        style: {
                            numberFormat: "0.00"
                        },
                        showTotal: true
                    },
                    J: {
                        key: 'prodMrktCode',
                        style: {
                            bold: false,
                            italic: false
                        },
                        showTotal: false
                    }
                },
                rows: {
                    start: 15,
                    end: 100,
                    conditionalformatting: (field_value) => {
                        console.log(
                            'Executing conditonal formatting --> ' +
                            field_value
                        );
                        return field_value === true ?
                            {
                                bold: true,
                                fill: 'eeeeee'
                            } :
                            {};
                    },
                    conditionalformattingkey: 'isMain',
                    showTotal: true,
                    totalFormula: function(column,start, end) {
                        return "SUM(" + column + start + ':' + column + end + ")";
                    }
                },
                objectkey: 'quoteLines',
                firstColumnValue: 'A',
                lastColumnValue: 'J'
            }],
            TERMS_AND_CONDITIONS: [{
                text: 'Web Application Protector plus Ion includes 1 Domain, 1 Security Policy, 5 Rate Policies (per Security Configuration), 1 Security Configuration and 1 Site Shield Map.',
                column: 'A',
                STYLE: {
                    bold: true,
                    italic: true
                }
            }],
            DISCLAMER: {
                text: 'Akamai Technologies - Confidential',
                column: 'A',
                STYLE: {
                    bold: true,
                    italic: true
                }
            }
        },
        BINARY_DATA: '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'
    };
};