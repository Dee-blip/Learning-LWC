@isTest
public class TestInformaticaPhoneVerificationResponse {
    static testMethod void testParse() {
            String json=            '{'+
            '  "WebServiceResponse": {'+
            '    "@xmlns": "http://ws.strikeiron.com",'+
            '    "SubscriptionInfo": {'+
            '      "@xmlns": "http://ws.strikeiron.com",'+
            '      "LicenseStatusCode": "0",'+
            '      "LicenseStatus": "Valid license key",'+
            '      "LicenseActionCode": "0",'+
            '      "LicenseAction": "Decremented hit count",'+
            '      "RemainingHits": "1193",'+
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
            InformaticaPhoneVerificationResponse obj = InformaticaPhoneVerificationResponse.parse(json);
            System.assert(obj != null);
        }
}