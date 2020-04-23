##
## Copyright 2020 Free Software Foundation, Inc.
##
## This file is part of GNU Radio
##
## SPDX-License-Identifier: GPL-3.0-or-later
##
##
<%
    namespace = header_info['namespace']
    modname = header_info['module_name']
%>\
${license}

/* This file is automatically generated using bindtool */

#include <pybind11/pybind11.h>
#include <pybind11/complex.h>
#include <pybind11/stl.h>

namespace py = pybind11;

#include <${prefix_include_root}/${basename}.h>
// pydoc.h is automatically generated in the build directory
#include <${basename}_pydoc.h>

void bind_${basename}(py::module& m)
{
${render_namespace(namespace=namespace,modname=[modname],modvar='m')}
}

<%def name='render_constructor()' >
</%def>

<%def name='render_function(fcn,fcn_list,cls_name,filter_val,isfree=False,modvar="",doc_prefix="")' >
<%
fcn_args = fcn['arguments']
fcn_name = fcn['name']
has_static = fcn['has_static'] if 'has_static' in fcn else False
matcher = lambda x,name: x['name'] == name
matched_list = [f for f in fcn_list if matcher(f,fcn_name)]
overloaded = len(matched_list) > 1
overloaded_str = ''
index_str = ''
if overloaded:
  index_into_list = matched_list.index(fcn)
  index_str = ','+str(index_into_list)
  overloaded_str = '({} ({}::*)({}))'.format(fcn['return_type'],cls_name,', '.join([f['dtype'] for f in fcn_args]))
%>\
% if fcn['name'] != filter_val:
        ${modvar if isfree else ""}${".def_static" if has_static and not isfree else ".def"}("${fcn['name']}",${overloaded_str}&${cls_name}::${fcn['name']},
% for arg in fcn_args:
            py::arg("${arg['name']}")${" = " + arg['default'] if arg['default'] else ''},
% endfor ## args 
            D(${doc_prefix}${cls_name},${fcn['name']}${index_str})
        )${';' if isfree else ""}
% endif ## Not a filtered function name
</%def>

<%def name='render_free_function(fcn,fcn_list,namespace_name,filter_val,modvar="",doc_prefix="")' >
<%
fcn_args = fcn['arguments']
fcn_name = fcn['name']
has_static = fcn['has_static'] if 'has_static' in fcn else False
matcher = lambda x,name: x['name'] == name
matched_list = [f for f in fcn_list if matcher(f,fcn_name)]
overloaded = len(matched_list) > 1
overloaded_str = ''
index_str = ''
if overloaded:
  index_into_list = matched_list.index(fcn)
  index_str = ','+str(index_into_list)
  overloaded_str = '({} ({}::*)({}))'.format(fcn['return_type'],'',', '.join([f['dtype'] for f in fcn_args]))
%>\
% if fcn['name'] != filter_val:
        ${modvar}.def("${fcn['name']}",${overloaded_str}&${namespace_name}::${fcn['name']},
% for arg in fcn_args:
            py::arg("${arg['name']}")${" = " + arg['default'] if arg['default'] else ''},
% endfor ## args 
            D(${doc_prefix}${fcn['name']}${index_str})
        );
% endif ## Not a filtered function name
</%def>

<%def name='render_namespace(namespace, modname, modvar)'>
<%
    classes=namespace['classes'] if 'classes' in namespace else []
    free_functions=namespace['free_functions'] if 'free_functions' in namespace else []
    free_enums = namespace['enums'] if 'enums' in namespace else []
    subnamespaces = namespace['namespaces'] if 'namespaces' in namespace else []
    doc_prefix = '' if len(modname) == 1 else ','.join(modname[1:])+','
%>\
% for cls in classes:
% if classes:
    using ${cls['name']}    = ${namespace['name']}::${cls['name']};
% endif ##classes
% endfor ##classes
% for cls in classes:

<%
member_functions = cls['member_functions'] if 'member_functions' in cls else []
constructors = cls['constructors'] if 'constructors' in cls else []
class_enums = cls['enums'] if 'enums' in cls else []
class_variables = cls['variables'] if 'variables' in cls else []
try:
        def find_make_function(member_fcns):
            for mf in member_fcns:
                if mf['name'] == 'make':
                    return mf
            return None

        make_function = find_make_function(member_functions)
except:
        make_function = None

isablock = False
if 'bases' in cls:
  base_str = '::'.join(list(filter(lambda x: x != '::',cls['bases'])))
  bases_with_block = [s for s in cls['bases'] if 'block' in s]
  if bases_with_block:
    isablock = True
    # The goal is to make gr::sync_block have the entire chain back to basic_block
    #  if base_str == gr::sync_block, base_str == gr::sync_block,gr::block,gr::basic_block
    if (base_str.endswith('gr::sync_block') or 
          base_str.endswith('gr::sync_interpolator') or 
          base_str.endswith('gr::sync_decimator') or 
          base_str.endswith('gr::tagged_stream_block')):
        base_str += ", gr::block"
    if base_str.endswith('gr::block'):
        base_str += ", gr::basic_block"
%>
    py::class_<${cls['name']}\
% if 'bases' in cls:
, ${base_str},
% else: 
,
% endif\
 
        std::shared_ptr<${cls['name']}>>(${modvar}, "${cls['name']}", D(${doc_prefix}${cls['name']}))

% if make_function: ## override constructors with make function
<%
fcn = make_function
fcn_args = fcn['arguments']
%>\
        .def(py::init(&${cls['name']}::${make_function['name']}),
% for arg in fcn_args:
           py::arg("${arg['name']}")${" = " + arg['default'] if arg['default'] else ''},
% endfor 
           D(${doc_prefix}${cls['name']},${make_function['name']})
        )
        
% else:
% for fcn in constructors:
<%
fcn_args = fcn['arguments']
%>\
\
% if len(fcn_args) == 0:
        .def(py::init<>(),D(${doc_prefix}${cls['name']},${cls['name']},${loop.index}))
%else:
        .def(py::init<\
% for arg in fcn_args:
${arg['dtype']}${'>(),' if loop.index == len(fcn['arguments'])-1 else ',' }\
% endfor ## args
\
% for arg in fcn_args:
           py::arg("${arg['name']}")${" = " + arg['default'] if arg['default'] else ''},
% endfor 
           D(${doc_prefix}${cls['name']},${cls['name']},${loop.index})
        )
% endif
% endfor ## constructors
% endif ## make

% for fcn in member_functions:
${render_function(fcn=fcn,fcn_list=member_functions,cls_name=cls['name'],filter_val='make',doc_prefix=doc_prefix)}
% endfor ## member_functions
        ;
% endfor ## classes

% if free_enums:
% for en in free_enums:
<%
values = en['values']
%>\
    py::enum_<${namespace['name']}::${en['name']}>(${modvar},"${en["name"]}")
% for val in values:
        .value("${val[0]}", ${namespace['name']}::${val[0]}) // ${val[1]}
% endfor 
        .export_values()
    ;
% endfor
% endif

% if free_functions:
% for fcn in free_functions:
${render_free_function(fcn=fcn,fcn_list=free_functions,namespace_name=namespace['name'],filter_val="",modvar=modvar,doc_prefix=doc_prefix)}
% endfor ## free_functions
% endif ## free_functions
\
% for sns in subnamespaces:
<%  
  submod_name = sns['name'].split('::')[-1]
  next_modvar = modvar + '_' + submod_name
%>
        py::module ${next_modvar} = ${modvar}.def_submodule("${submod_name}");
${render_namespace(namespace=sns,modname=modname+[submod_name],modvar=next_modvar)}
% endfor

</%def>