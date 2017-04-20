from bioblend import galaxy

gi = galaxy.GalaxyInstance(url='http://127.0.0.1:8080', key='06a10112ad338c0a1bc4cabb6def4634')


data1 = '417e33144b294c21'
data2 = '1e8ab44153008be8'
workflow = 'f2db41e1fa331b3e'
datamap = dict()
datamap[0] = {'src': 'ldda', 'id': data1}
datamap[1] = {'src': 'ldda', 'id': data2}
result = gi.workflows.run_workflow(workflow, datamap,import_inputs_to_history=True)
