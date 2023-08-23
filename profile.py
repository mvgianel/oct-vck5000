"""OCT Alveo V70 profile with post-boot script
"""

# Import the Portal object.
import geni.portal as portal
# Import the ProtoGENI library.


# Import the Portal object.
import geni.portal as portal
# Import the ProtoGENI library.
import geni.rspec.pg as pg
# We use the URN library below.
import geni.urn as urn
# Emulab extension
import geni.rspec.emulab

# Create a portal context.
pc = portal.Context()

# Create a Request object to start building the RSpec.
request = pc.makeRequestRSpec()

# Variable number of nodes.
pc.defineParameter("nodeCount", "Number of Nodes", portal.ParameterType.INTEGER, 1,
                   longDescription="Enter the number of FPGA nodes. Maximum is 4.")

# Pick your image.
imageList = [('urn:publicid:IDN+emulab.net+image+emulab-ops//UBUNTU20-64-STD', 'UBUNTU 20.04'),
             ('urn:publicid:IDN+emulab.net+image+emulab-ops//UBUNTU22-64-STD', 'UBUNTU 22.04')] 

#toolVersion = [('2023.1')]
                   
#pc.defineParameter("toolVersion", "Tool Version",
#                   portal.ParameterType.STRING,
#                   toolVersion[0], toolVersion,
#                   longDescription="Select a tool version. It is recommended to use the latest version for the deployment workflow. For more information, visit https://www.xilinx.com/products/boards-and-kits/alveo/u280.html#gettingStarted")   
pc.defineParameter("osImage", "Select Image",
                   portal.ParameterType.IMAGE,
                   imageList[0], imageList,
                   longDescription="Supported operating systems are Ubuntu and CentOS.")                    

# Retrieve the values the user specifies during instantiation.
params = pc.bindParameters()        

# Check parameter validity.

if params.nodeCount < 1 or params.nodeCount > 4:
    pc.reportError(portal.ParameterError("The number of FPGA nodes should be greater than 1 and less than 4.", ["nodeCount"]))
    pass
  
pc.verifyParameters()

# Process nodes, adding to FPGA network
for i in range(params.nodeCount):
    # Create a node and add it to the request
    name = "node" + str(i)
    node = request.RawPC(name)
    node.disk_image = params.osImage
    # Assign to the node hosting the FPGA.
    node.hardware_type = "fpga-alveo"
    node.component_manager_id = "urn:publicid:IDN+cloudlab.umass.edu+authority+cm"
    node.addService(pg.Execute(shell="bash", command="sudo /local/repository/post-boot.sh  >> /local/repository/output_log.txt")) 
    pass
pc.printRequestRSpec(request)
