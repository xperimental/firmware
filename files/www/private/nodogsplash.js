
function mark_mac_list()
{
    onDesc(get("nds_status"), 'SPAN', function(e) {
        e.onclick = function() {
            var mac = this.textContent;
            var ul = get('mac_list');

            onChilds(ul, 'LI', function(e) { if(e.textContent == mac) mac = ""; });
            if(mac.length == 0) return;

            var li = create('li');
            li.onclick = function() { ul.removeChild(this); };
            li.appendChild(document.createTextNode(mac));

            ul.appendChild(li);
        };
    });
}

function reload()
{
    send("/cgi-bin/nodogsplash", { func: "get_status" }, function(text) {
        if(text.length == 0) return;
        text = text.replace(/([0-9a-f]{1,2}(:[0-9a-f]{1,2}){5})/gi, "<span class='nds_mac'>$1</span>");
        setText('nds_status', text);
        mark_mac_list();
    });
}

function button_action(func)
{
    var macs = "";
    onChilds(get('mac_list'), 'LI', function(e) { macs += " " + e.textContent; });

    if(macs.length == 0) return;
    send("/cgi-bin/nodogsplash", { func : func, macs : macs }, function(data) {
        setText('msg', data);
    });
}

reload();
