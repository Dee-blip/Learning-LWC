({
    parseTextHelper: function (cmp, event, content) {

        var parsedContent = this.linkFindandParseHelper(content);
        //setting the actual parse content
        //console.log('-->',parsedContent);
        cmp.set('v.parsecontent', parsedContent);
    },
    linkFindandParseHelper: function (content) {
        //var url_regex = new RegExp("(?:http(s)?:\\/\\/)?[\\w.-]+(?:\\.[\\w\\.-]+)+[\\w\\-\\._~:\\/?#[\\]@!\\$&'\\(\\)\\*\\+,;=.]+",'gm');
        var url_regex = new RegExp("(https?:\\/\\/(?:www\\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\\.[^\\s]{2,}|www\\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\\s]{2,}|https?:\\/\\/(?:www\\.|(?!www))[a-zA-Z0-9]\\.[^\\s]{2,}|www\\.[a-zA-Z0-9]\\.[^\\s]{2,})", 'gm');
        var phone_regex = new RegExp("\\d{3}-\\d{3}-\\d{4}", "gm");
        var email_regex = new RegExp("([\\w]+[.\\-#]?[\\w]+@{1}[\\w]{3,}([.][\\w]{2,})+)", "gm");

        let parsed = content;

        var url_matches = content.match(url_regex);
        var phone_matches = content.match(phone_regex);
        var email_matches = content.match(email_regex);
        //console.log(phone_matches)
        var match_object = {
            'url': url_matches ? [...url_matches] : [],
            'phone': phone_matches ? [...phone_matches] : [],
            'email': email_matches ? [...email_matches] : []
        };
        console.log(match_object)
        if (match_object) {
            for (var item in match_object) {
                //console.log(item);
                match_object[item].map((match, idx) => {
                    //console.log(match,idx)
                    if (item === 'url') {
                        let https = '';
                        if (!match.startsWith('http')) { https = 'https://'; }
                        parsed = parsed.replace(match, `<a href="${https}${match}" target="_blank">${match}<\/a>`);
                    } else if (item === 'phone') {
                        parsed = parsed.replace(match, `<a href="tel:${match}">${match}<\/a>`);
                    } else if (item === 'email') {
                        parsed = parsed.replace(match, `<a href="mailto:${match}">${match}<\/a>`);
                    }

                });
            }
        }
        return parsed;
    }

})