@isTest
public class TestInformaticaEmailVerificationResponse{

    static testMethod void testParse() {
        
            String json=            '{'+
            '  "WebServiceResponse": {'+
            '}'+
            '}';
            
            InformaticaEmailVerificationResponse obj = InformaticaEmailVerificationResponse.parse(json);
            System.assert(obj != null);
            Boolean responeValue = InformaticaAddressDoctorUtil.verifyEmailResponse(obj);
        
            String json2=  '{}';
            InformaticaEmailVerificationResponse obj2= InformaticaEmailVerificationResponse.parse(json2);
            Boolean responeValue2 = InformaticaAddressDoctorUtil.verifyEmailResponse(obj2);
            system.assertEquals(responeValue2,false);
        
        
            String json3 = '{'+
            '    \"WebServiceResponse\": {'+
            '        \"@xmlns\": \"http://ws.strikeiron.com\",'+
            '        \"SubscriptionInfo\": {'+
            '            \"@xmlns\": \"http://ws.strikeiron.com\",'+
            '            \"LicenseStatusCode\": \"0\",'+
            '            \"LicenseStatus\": \"Valid license key\",'+
            '            \"LicenseActionCode\": \"0\",'+
            '            \"LicenseAction\": \"Decremented hit count\",'+
            '            \"Amount\": \"0\"'+
            '        },'+
            '        \"VerifyEmailResponse\": {'+
            '            \"@xmlns\": \"http://www.strikeiron.com/\",'+
            '            \"VerifyEmailResult\": {'+
            '                \"ServiceStatus\": {'+
            '                    \"StatusNbr\": \"200\",'+
            '                    \"StatusDescription\": \"Email Valid\"'+
            '                },'+
            '                \"ServiceResult\": {'+
            '                    \"Reason\": {'+
            '                        \"Code\": \"201\",'+
            '                        \"Description\": \"Mailbox Confirmed\"'+
            '                    },'+
            '                    \"HygieneResult\": \"Safe US\",'+
            '                    \"NetProtected\": \"false\",'+
            '                    \"NetProtectedBy\": null,'+
            '                    \"SourceIdentifier\": \"\\\"\\\"\",'+
            '                    \"Email\": \"test@akamai.com\",'+
            '                    \"LocalPart\": \"shivamverma02\",'+
            '                    \"DomainPart\": \"gmail.com\",'+
            '                    \"IronStandardCertifiedTimestamp\": \"2015-05-14T08:59:14.54\",'+
            '                    \"DomainKnowledge\": null,'+
            '                    \"AddressKnowledge\": {'+
            '                        \"StringKeyValuePair\": {'+
            '                            \"Key\": \"Cached\",'+
            '                            \"Value\": \"true\"'+
            '                        }'+
            '                    }'+
            '                }'+
            '            }'+
            '        }'+
            '    }'+
            '}';
            InformaticaEmailVerificationResponse obj3 = InformaticaEmailVerificationResponse.parse(json3);
            System.assert(obj3 != null);
            Boolean responeValue3 = InformaticaAddressDoctorUtil.verifyEmailResponse(obj3);
            system.assertEquals(responeValue3,false);

            String json4 = '{'+
            '    \"WebServiceResponse\": {'+
            '        \"@xmlns\": \"http://ws.strikeiron.com\",'+
            '        \"SubscriptionInfo\": {'+
            '            \"@xmlns\": \"http://ws.strikeiron.com\",'+
            '            \"LicenseStatusCode\": \"0\",'+
            '            \"LicenseStatus\": \"Valid license key\",'+
            '            \"LicenseActionCode\": \"0\",'+
            '            \"LicenseAction\": \"Decremented hit count\",'+
            '            \"Amount\": \"0\"'+
            '        },'+
            '        \"VerifyEmailResponse\": {'+
            '            \"@xmlns\": \"http://www.strikeiron.com/\",'+
            '            \"VerifyEmailResult\": {'+
            '                \"ServiceStatus\": {'+
            '                    \"StatusNbr\": \"200\",'+
            '                    \"StatusDescription\": \"Email Valid\"'+
            '                },'+
            '                \"ServiceResult\": {'+
            '                 \"HygieneResult\": \"Safe US\",'+
            '                    \"NetProtected\": \"false\",'+
            '                    \"NetProtectedBy\": null,'+
            '                    \"SourceIdentifier\": \"\\\"\\\"\",'+
            '                    \"Email\": \"test@akamai.com\",'+
            '                    \"LocalPart\": \"shivamverma02\",'+
            '                    \"DomainPart\": \"gmail.com\",'+
            '                    \"IronStandardCertifiedTimestamp\": \"2015-05-14T08:59:14.54\",'+
            '                    \"DomainKnowledge\": null,'+
            '                    \"AddressKnowledge\": {'+
            '                        \"StringKeyValuePair\": {'+
            '                            \"Key\": \"Cached\",'+
            '                            \"Value\": \"true\"'+
            '                        }'+
            '                    }'+
            '                }'+
            '            }'+
            '        }'+
            '    }'+
            '}';
            InformaticaEmailVerificationResponse obj4 = InformaticaEmailVerificationResponse.parse(json4);
            Boolean responeValue4 = InformaticaAddressDoctorUtil.verifyEmailResponse(obj4);
            system.assertEquals(responeValue4,false);

            String json5 = '{'+
            '    \"WebServiceResponse\": {'+
            '        \"@xmlns\": \"http://ws.strikeiron.com\",'+
            '        \"SubscriptionInfo\": {'+
            '            \"@xmlns\": \"http://ws.strikeiron.com\",'+
            '            \"LicenseStatusCode\": \"0\",'+
            '            \"LicenseStatus\": \"Valid license key\",'+
            '            \"LicenseActionCode\": \"0\",'+
            '            \"LicenseAction\": \"Decremented hit count\",'+
            '            \"RemainingHits\": \"9972\",'+
            '            \"Amount\": \"0\"'+
            '        },'+
            '        \"VerifyEmailResponse\": {'+
            '            \"@xmlns\": \"http://www.strikeiron.com/\",'+
            '            \"VerifyEmailResult\": {'+
            '                \"ServiceStatus\": {'+
            '                    \"StatusNbr\": \"200\",'+
            '                    \"StatusDescription\": \"Email Valid\"'+
            '                }'+
            '            }'+
            '        }'+
            '    }'+
            '}';
            InformaticaEmailVerificationResponse obj5 = InformaticaEmailVerificationResponse.parse(json5);

            Boolean responeValue5 = InformaticaAddressDoctorUtil.verifyEmailResponse(obj5);
                        system.assertEquals(responeValue5,false);

                        String json6 = '{'+
            '    \"WebServiceResponse\": {'+
            '        \"@xmlns\": \"http://ws.strikeiron.com\",'+
            '        \"SubscriptionInfo\": {'+
            '            \"@xmlns\": \"http://ws.strikeiron.com\"'+
            '        }'+
            '    }'+
            '}';
            InformaticaEmailVerificationResponse obj6 = InformaticaEmailVerificationResponse.parse(json6);

            Boolean responeValue6 = InformaticaAddressDoctorUtil.verifyEmailResponse(obj6);
                        system.assertEquals(responeValue6,false);

String json7 = '{'+
            '    \"WebServiceResponse\": {'+
            '        \"@xmlns\": \"http://ws.strikeiron.com\",'+
            '        \"SubscriptionInfo\": {'+
            '            \"@xmlns\": \"http://ws.strikeiron.com\",'+
            '            \"LicenseStatusCode\": \"0\",'+
            '            \"LicenseStatus\": \"Valid license key\",'+
            '            \"LicenseActionCode\": \"0\",'+
            '            \"LicenseAction\": \"Decremented hit count\",'+
            '            \"RemainingHits\": \"9972\",'+
            '            \"Amount\": \"0\"'+
            '        },'+
            '        \"VerifyEmailResponse\": {'+
            '            \"@xmlns\": \"http://www.strikeiron.com/\",'+
            '            \"VerifyEmailResult\": {'+
            '                \"ServiceStatus\": {'+
            '                }'+
            '            }'+
            '        }'+
            '    }'+
            '}';
            InformaticaEmailVerificationResponse obj7 = InformaticaEmailVerificationResponse.parse(json7);

            Boolean responeValue7 = InformaticaAddressDoctorUtil.verifyEmailResponse(obj7);
                        system.assertEquals(responeValue7,false);

                        String json8 = '{'+
            '    \"WebServiceResponse\": {'+
            '        \"@xmlns\": \"http://ws.strikeiron.com\",'+
            '        \"SubscriptionInfo\": {'+
            '            \"@xmlns\": \"http://ws.strikeiron.com\",'+
            '            \"LicenseStatusCode\": \"0\",'+
            '            \"LicenseStatus\": \"Valid license key\",'+
            '            \"LicenseActionCode\": \"0\",'+
            '            \"LicenseAction\": \"Decremented hit count\",'+
            '            \"RemainingHits\": \"9972\",'+
            '            \"Amount\": \"0\"'+
            '        },'+
            '        \"VerifyEmailResponse\": {'+
            '            \"@xmlns\": \"http://www.strikeiron.com/\",'+
            '            \"VerifyEmailResult\": {'+
            '            }'+
            '        }'+
            '    }'+
            '}';
            InformaticaEmailVerificationResponse obj8 = InformaticaEmailVerificationResponse.parse(json8);

            Boolean responeValue8 = InformaticaAddressDoctorUtil.verifyEmailResponse(obj8);
                        system.assertEquals(responeValue8,false);



        
        
        }
    
    static testMethod void testParse2() {
            String json=            '{'+
            '  "WebServiceResponse": {'+
            '}'+
            '}';
            
            InformaticaPhoneVerificationResponse obj = InformaticaPhoneVerificationResponse.parse(json);
            System.assert(obj != null);
            Boolean responeValue = InformaticaAddressDoctorUtil.verifyPhoneResponse(obj);
            system.assertEquals(responeValue,false);
        
            String json2=  '{}';
            InformaticaPhoneVerificationResponse obj2= InformaticaPhoneVerificationResponse.parse(json2);
            Boolean responeValue2 = InformaticaAddressDoctorUtil.verifyPhoneResponse(obj2);
            system.assertEquals(responeValue2,false);

        
        String json3 = '{'+
            '  "WebServiceResponse": {'+
            '    "@xmlns": "http://ws.strikeiron.com",'+
            '    "SubscriptionInfo": {'+
            '      "@xmlns": "http://ws.strikeiron.com",'+
            '      "LicenseStatusCode": "0",'+
            '      "LicenseStatus": "Valid license key",'+
            '      "LicenseActionCode": "0",'+
            '      "LicenseAction": "Decremented hit count",'+
            '      "Amount": "0"'+
            '    },'+
            '    "ValidateNumberISOResponse": {'+
            '      "@xmlns": "http://www.strikeiron.com",'+
            '      "ValidateNumberISOResult": {'+
            '        "ServiceStatus": {'+
            '          "StatusNbr": "200",'+
            '          "StatusDescription": "Successful"'+
            '        },'+
            '        "ServiceResult": {'+
            '          "Results": {'+
            '            "GlobalPhoneEntryWithStatus": {'+
            '              "ItemStatus": {'+
            '                "StatusNbr": "201",'+
            '                "StatusDescription": "Valid Number"'+
            '              },'+
            '              "Listing": {'+
            '                "Number": "919980052222",'+
            '                "CountryCode": "91",'+
            '                "InternationalPrefix": "00",'+
            '                "NationalPrefix": "0",'+
            '                "CellPrefix": null,'+
            '                "NDC": "99800",'+
            '                "SN_From": "0",'+
            '                "SN_To": "99999",'+
            '                "Uses_NDC": "true",'+
            '                "Number_Type": "Mobile",'+
            '                "CarrierName": "Bharti Airtel Ltd",'+
            '                "Language": "hi",'+
            '                "Country": "356",'+
            '                "ISO": "IN",'+
            '                "RegionCode": "KA",'+
            '                "RegionName": "Karnātaka",'+
            '                "City": "Mobile Telephony",'+
            '                "TimeZone": "Asia/Kolkata",'+
            '                "UTC": "+05:30",'+
            '                "DST": "false",'+
            '                "Latitude": "15.317277",'+
            '                "Longitude": "75.713888",'+
            '                "ErrorCode": "NoError"'+
            '              }'+
            '            }'+
            '          }'+
            '        }'+
            '      }'+
            '    }'+
            '  }'+
            '}';
            
            InformaticaPhoneVerificationResponse obj3= InformaticaPhoneVerificationResponse.parse(json3);
            Boolean responeValue3 = InformaticaAddressDoctorUtil.verifyPhoneResponse(obj3);
            system.assertEquals(responeValue3,true);



        }
}