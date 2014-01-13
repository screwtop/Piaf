-- Database model for my simple Edita text editor

-- Things to store:
-- Projects (collections of related files)
-- Recent files
-- Maybe a log of all operations for more advanced undo/redo/repeat and general rewriting of history.
-- Script text?
-- Language extensions (e.g. lexical highlighting rules, language-specific Insert snippets).
-- Spelling and grammar data.
-- Unicode character data.

-- Should the model assume a single user (perhaps put the database file in ~/.edita) or multiple users?  It would be easy enough to record <hostname, username> along with each record, so the data could be cloudified and shared universally.


-- TODO: think about how to upgrade an existing user database.  Don't really want (and shouldn't really need) to blow it away.  Schema change management, bleah!


-- For now, let's just assume the install script will just delete any existing database file!

create table File_Log
(
	Hostname varchar,
	Username varchar,
	Filename varchar,
--	PID?
	Date_Performed timestamp with time zone,
	Operation varchar,

	constraint File_Log_PK primary key (Hostname, Username, Filename, Date_Performed)
);


create table Project
(
	Username	varchar,
	Project_Name	varchar,
	Date_Created	timestamp with time zone
);

-- Files associated with a particular project:
--create table Project_Files ();


-- How come these have no effect?
.exit
.quit
