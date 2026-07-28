**FREE

/if not defined(LUTIL_H)
/define LUTIL_H


///
// Linked List Utilities
//
// This module contains several procedures which uses the linked
// list procedures for storing simple data.
//
// @author Mihael Schmidt
// @date   23.02.2008
// @project Linked List
//
// @rev 15.03.2008 Mihael Schmidt
//      added procedure lutil_listObjects
//
// @rev 18.03.2009 Mihael Schmidt
//      added procedure lutil_listDatabaseRelations
///


//------------------------------------------------------------------------------
//                          The MIT License (MIT)
//
// Copyright (c) 2017 Mihael Schmidt
//
// Permission is hereby granted, free of charge, to any person obtaining a copy 
// of this software and associated documentation files (the "Software"), to deal 
// in the Software without restriction, including without limitation the rights 
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
// copies of the Software, and to permit persons to whom the Software is 
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in 
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
// SOFTWARE.
//------------------------------------------------------------------------------


//-------------------------------------------------------------------------
// Prototypes for Linked List Utilities
//-------------------------------------------------------------------------

///
// List file member names
//
// All member names of a file are placed into a linked list.
// This list is returned to the caller. On any error *null is
// returned.
//
// @author Mihael Schmidt
// @date   23.02.2008
//
// @param Library name
// @param File name
//
// @return pointer to list or *null if any error occurs
///
dcl-pr lutil_listFileMembers pointer extproc('lutil_listFileMembers');
  library char(10) const;
  filename char(10) const;
end-pr;

///
// List record format names
//
// All record format names of a file are placed into a linked list.
// This list is returned to the caller. On any error *null is
// returned.
//
// @author Mihael Schmidt
// @date   25.02.2008
//
// @param Library name
// @param File name
//
// @return Pointer to list or *null if any error occured
///
dcl-pr lutil_listRecordFormats pointer extproc('lutil_listRecordFormats');
  library char(10) const;
  filename char(10) const;
end-pr;

///
// List objects
//
// All object names are placed into a linked list.
// This list is returned to the caller. On any error *null is
// returned.
//
// <br><br>
//
// The entries in the list have the following format:
// <ul>
//   <li>10A Library name</li>
//   <li>10A Object name</li>
//   <li>10A Object type</li>
// </ul>
//
// <br><br>
// As this procedure utilizes the QUSLOBJ i5/OS API the parameters
// here accept the same names and generic names for library, name and
// object type.
//
// @param Library
// @param Object name (default: *all)
// @param Object type (default: *all)
//
// @return Pointer to list or *null if any error occured
///
dcl-pr lutil_listObjects pointer extproc('lutil_listObjects');
  library char(10) const;
  object char(10) const options(*omit : *nopass);
  type char(10) const options(*nopass);
end-pr;

///
// List Job Library List
//
// All libraries of the library list of the specified job will be added
// in the order of the library list returned in a linked list.
//
// <br><br>
//
// The qualified job name consists of the following parts:
// <ul>
//   <li>CHAR (10) - Job Name</li>
//   <li>CHAR (10) - User Name</li>
//   <li>CHAR (6) - Job Number</li>
// </ul>
//
// <br>
//
// If both parameters are passed then the library list of the job with
// the qualified job name will be retrieved.
//
// @author Mihael Schmidt
// @date   10.04.2008
//
// @param Qualified Job Name (optinal, default = current job)
// @param Internal Job Number (optinal)
// @param Library parts (see LUTIL_LIBRARY_PART_*)
//
// @return Pointer to list or *null if any error occured
///
dcl-pr lutil_listJobLibraryList pointer extproc('lutil_listJobLibraryList');
  qualifiedJobName char(26) const options(*omit : *nopass);
  internalJobNumber char(16) const options(*omit : *nopass);
  libraryParts int(10) const options(*nopass);
end-pr;

///
// List Active Jobs in Subsystem
//
// All active jobs of the specified subsystem will be added to the list.
// The entries of the list are qualified job names which consist of the
// following parts:
// <ul>
//   <li>CHAR (10) - Job Name</li>
//   <li>CHAR (10) - User Name</li>
//   <li>CHAR (6) - Job Number</li>
// </ul>
//
// <br>
//
// Subsystem monitor jobs are exluded from the list.
//
// @author Mihael Schmidt
// @date   29.04.2008
//
// @param Subsystemdescription library
// @param Subsystemdescription name
//
// @return Pointer to list or *null if any error occured
//
// @info The user calling this procedure must have *JOBCTL
//       authorities else this procedure returns *null.
///
dcl-pr lutil_listActiveSubsystemJobs pointer extproc('lutil_listActiveSubsystemJobs');
  library char(10) const options(*nopass);
  name char(10) const options(*nopass);
end-pr;

///
// List database relations
//
// All database relations (logical files, views and indices) are added
// to the list. This list is returned to the caller. On any error *null is
// returned. If the file does not exist *null is returned. If the file has
// no relations an empty list is returned.
//
// <br><br>
//
// The entries in the list have the following format:
// <ul>
//   <li>10A File name</li>
//   <li>10A Library name</li>
// </ul>
//
// @author Mihael Schmidt
// @date   19.03.2009
//
// @param Library name
// @param File name
//
// @return pointer to list or *null if any error occurs
///
dcl-pr lutil_listDatabaseRelations pointer extproc('lutil_listDatabaseRelations');
  library char(10) const;
  file char(10) const;
end-pr;

///
// List jobs
//
// Returns a list of qualified job names which matches the passed parameters.
//
// <br><br>
//
// The qualified job name consists of the following parts:
// <ul>
//   <li>CHAR (10) - Job Name</li>
//   <li>CHAR (10) - User Name</li>
//   <li>CHAR (6) - Job Number</li>
// </ul>
//
// <br><br>
//
// Valid values for the job status are : *ACTIVE, *JOBQ, *OUTQ, *ALL.
//
// @author Mihael Schmidt
// @date   16.04.2009
//
// @param Qualified job name
// @param Job status (default: *ALL)
// @param Active job status (optional)
//
// @info For valid values for the parameters look at the i5/OS API QUSLJOB
//       and QUSRJOBI.
///
dcl-pr lutil_listJobs pointer extproc('lutil_listJobs');
  qualJobName char(26) const;
  status char(10) const options(*nopass);
  activeStatus char(4) const options(*nopass);
end-pr;

//-------------------------------------------------------------------------
// Data structure templates
//-------------------------------------------------------------------------
dcl-ds tmpl_qualifiedJobName qualified template;
  jobName char(10);
  userName char(10);
  jobNumber char(6);
end-ds;

/endif
