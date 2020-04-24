import os
import html
import json

# Flask 1.1.1
from flask import Flask, request, send_file, render_template, make_response

from lldp.lldp import get_list
from lldp.getinfo import build_topology
from lldp.wrs import apply_wr_status
from lldp.vis import get_root_name, visualize_graph
from lldp.graph import get_object_from_file, export_to_svg

template_name = 'home.html'
root_path = os.path.dirname(__file__)
oid_filename = 'lldp/oid.json'
svg_filename = 'lldp/output.svg'
graph_filename = 'lldp/graph.json'
topology_filename = 'lldp/topology.json'
wr_topology_filename = 'lldp/wr_topology.json'
oid_filepath = os.path.join(root_path, oid_filename)
svg_filepath = os.path.join(root_path, svg_filename)
graph_filepath = os.path.join(root_path, graph_filename)
topology_filepath = os.path.join(root_path, topology_filename)
wr_topology_filepath = os.path.join(root_path, wr_topology_filename)
atd_filepath = os.path.join(root_path, 'lldp/allTimingDevices.txt')
ret_status = {
    0: "ok",
    1: "Verify your network connection or WR switch",
    2: "Provide a valid switch name",
    3: "Bad OID file: not available, invalid JSON, empty",
    4: "Bad topology file: not available, invalid JSON description",
    5: "Export failed! Verify topology file",
    6: "Network graph not found! (Hint: build it by providing a root switch)"
}

app = Flask(__name__)
#app.config['USE_X_SENDFILE'] = True # set the X-Sendfile header, supported by Apache

@app.route("/")
def get():
    ret_code = 0

    # get network topology, extend with WR status, re-generate graph JSON
    if request.args.get('rebuildBtn'):
        root_wrs = request.args.get('rootWrs')
        if root_wrs != '':
            # get a list of network devices
            device_list = get_list(root_wrs)
            build_topology(oid_filepath, device_list, topology_filepath)
            ret_code =  update_wr(oid_filepath, topology_filepath, graph_filepath, wr_topology_filepath)
        else:
            ret_code = 2 # missing switch name

    # get WR status, re-generate graph JSON
    elif request.args.get('updateBtn'):
        # get WR status, if network devices are unreachable (raises exception), then inform user
        ret_code =  update_wr(oid_filepath, topology_filepath, graph_filepath, wr_topology_filepath)

    # export network topology to SVG
    elif request.args.get('exportBtn'):

        # get JSON description of network, get None if fails
        network_json = get_object_from_file(wr_topology_filepath)

        # get name of root switch, get empty if fails
        root_wrs = get_root_name(network_json)
        if root_wrs:
            if export_to_svg(network_json, root_wrs, svg_filepath):
                return send_file(svg_filepath, as_attachment=True, cache_timeout=5)
            else:
                ret_code = 5 # export failure
        else:
            ret_code = 4 # bad topology

    # re-build web page
    return rebuild(ret_code)

def rebuild(ret_code):
    def_network = {  # example network
        'nodes': [
            {'id': 0, 'label': 'node 0'}, {'id': 1, 'label': 'node 1'}
        ],
        'edges' : [
            {'source': 0, 'target': 1}
        ]
    }

    data = {
        'gephi':    json.dumps(def_network),  # encode to JSON
        'ret_code': ret_code,            # include return status of subprocess call
        'ret_msg':  ret_status.get(ret_code)
    }

    if ret_code != 0:
        return render_template(template_name, data=data)

    if os.path.exists(graph_filepath):
        json_str = None
        with open(graph_filepath, 'r') as jsonfile:
            json_str = jsonfile.read()

            try:
                gephi = json.loads(json_str)  # verify a string with JSON by decoding it to Python object
                data['gephi'] = json_str      # update gephi's value
            except:
                data['ret_code'] = 1
                data['ret_msg'] = "Invalid JSON format in %s. " % graph_filename + ret_status.get(ret_code)

    else:
        data['ret_code'] = 6
        data['ret_msg'] = ret_status.get(ret_code)

    return render_template(template_name, data=data)

def update_wr(oid_filepath, topology_filepath, graph_filepath, wr_topology_filepath):
    ''' Update network topology with WR status'''

    oid = {}              # OID
    network_json = {}     # network description in JSON
    wr_network_json = {}  # WR network description in JSON

    # Load OID data
    with open(oid_filepath) as oidlist:
        oid = json.load(oidlist)

    if not oid:
        return 3 # bad OID file

    # get network topology
    network_json = get_object_from_file(topology_filepath)

    if not network_json:
        return 4 # bad topology file

    # get WR status and apply it to the network topology
    try:
        wr_network_json = apply_wr_status(network_json, oid)
    except:
        return 1 # networking issue

    # generate graph
    root_name = get_root_name(wr_network_json)

    if root_name == '':
        return 1 # networking issue

    graph = visualize_graph(wr_network_json, root_name)

    with open(graph_filepath, 'w') as f:
        json.dump(graph, f, sort_keys=True, indent=4, separators=(',', ': '))

    with open(wr_topology_filepath, 'w') as f:
        json.dump(wr_network_json, f, sort_keys=False, indent=4, separators=(',', ': '))

@app.route("/lookup/")
def lookup():

    node_label = request.args.get('node')

    if node_label.startswith('WR '):            # label format is 'WR mac_addr'
        node_label = node_label.replace('WR ', '')

        if not ':' in node_label:               # bad format, ':' is missing in mac_addr
            node_label = ':'.join(node_label[i:i+2] for i in range(0,12,2))

    node_label = str(node_label)
    result = node_label

    atd_content = []

    if len(atd_content) == 0:
        with open(atd_filepath) as atd_file:
            atd_content = atd_file.readlines()

    for line in atd_content:
        if line.find(node_label) != -1:
            result += '\n' + line

    return make_response(result)

# call command line script in [1]
# [1] https://adamj.eu/tech/2019/04/03/django-versus-flask-with-single-file-applications/
# [2] https://flask.palletsprojects.com/en/1.1.x/
