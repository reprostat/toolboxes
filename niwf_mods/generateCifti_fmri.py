from argparse import ArgumentParser
from pathlib import Path
from niworkflows.interfaces.cifti import GenerateCifti
from nipype.pipeline.engine import Node
from shutil import move

# Parse arguments
parser = ArgumentParser(description='Generate CIfTI dense timeseries from volumetric and surface BOLD data')
parser.add_argument('--vol',nargs=1,type=Path,default=None,help='Volumetric BOLD data')
parser.add_argument('--surf',nargs=2,type=str,default=None,help='Surface BOLD data as list [LH, RH]')
parser.add_argument('--tr',nargs=1,type=float,default=None,help='TR')
args = parser.parse_args();

out = Node(GenerateCifti(TR=args.tr[0], bold_file=str(args.vol[0]), surface_bolds=args.surf),
           name="Generate_CIfTI").run().outputs

move(out.out_file,args.vol[0].with_suffix('.dtseries.nii'))
move(out.out_metadata,args.vol[0].with_suffix('.dtseries.json'))
