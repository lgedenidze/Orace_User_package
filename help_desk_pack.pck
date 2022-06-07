create or replace package help_desk_pack is
--
procedure create_user(p_ora_name varchar2, p_position varchar2 default 'SUPPORT MANAGER',p_email varchar2 default null );
----
PROCEDURE update_role(p_ora_name varchar2,p_menu_id number);
----
procedure give_other_users_roles (p_ora_name_to varchar2,p_ora_name_from varchar2);
--
procedure unlock_user (p_ora_name varchar2,p_lock varchar2  default 'UNLOCK');
---
procedure change_user_password(p_ora_name varchar2, p_password varchar2);

--
procedure kill_seasion (p_username varchar2 );
--
procedure create_new_vabank_user (p_username varchar2,p_ora_name varchar2);
--
procedure new_vabank_role (p_ora_name varchar2,p_role_name varchar2);

--
procedure update_position (p_ora_name krn_user.ora_name%type, p_position krn_user.position%type);

--


procedure create_only_new_vabank  (p_ora_name krn_user.ora_name%type,
                                                         p_username bpm_users.domain_user%type,
                                                         p_new_vabank_role_name bpm_roles.role_name%type );

--
---pack by lgedenidze
end;
/
create or replace package body help_desk_pack is
--

procedure create_user(p_ora_name varchar2,
                                    p_position varchar2 default 'SUPPORT MANAGER',
                                    p_email    varchar2 default  null                            )  is

  cursor c_check_position(p_pos varchar2) is
    select * from krn_position a where a.pos_name = p_pos;

  cursor c_check_ora(p_ora varchar2) is
    select * from krn_user b where b.ora_name = p_ora;
---
  v_check_position  c_check_position%rowtype;
  v_check_ora          c_check_ora%rowtype;
  v_user                   krn_user.ora_name%type := upper(p_ora_name);
  v_id_menu            krn_menu.id%type := 9;
  v_counter              number;
  e_ora                     exception;
  e_position              exception;
begin

  open c_check_ora(p_ora_name);
  fetch c_check_ora
    into v_check_ora;

  if c_check_ora%found then
    close c_check_ora;
    raise e_ora;
  elsif c_check_ora%notfound then
    open c_check_position(p_position);
    fetch c_check_position
      into v_check_position;
    if c_check_position%notfound then raise e_position; close c_check_position;
  else
      execute immediate 'create user ' || v_user ||
                        ' identified by bank12345 profile VBXL_DEFAULT
                                           default tablespace SMALL_DATA temporary tablespace TEMP';
      execute immediate 'grant create session to ' || v_user;
---------
      insert into krn_user
        (ora_name,last_name,first_name,sex,position,department,branch,email,security_level,lang,created,acct_point)
       values
        (v_user,v_user,v_user,'M',p_position,'CENT00','502',p_email,'0','RUSSIAN',krn_sys.run_date,'BANK');
----------

      insert into krn_executive_code
        (exec_key,branch,code_desc,open_date,stop_date,locked,multiuser,menu_id,profile_key,parent_exec_key,inp_phase,chk_phase,eod_phase,sod_phase)
      values
        (v_user,'502',v_user,to_date('06-10-2021', 'dd-mm-yyyy'),to_date('01-01-4444', 'dd-mm-yyyy'),'N','Y',null,null,null,'Y','N','N','N');

------
      insert into krn_exec_user_link
        (beg_date, end_date, locked, ora_name, exec_key, def)
      values
        (to_date('01-05-2018', 'dd-mm-yyyy'),to_date('01-01-4444', 'dd-mm-yyyy'),'N',v_user,v_user,'N');
-------

      select max(id) into v_counter from krn_menu_links;

      v_counter := v_counter + 1;

      insert into krn_menu_links
        (id_menu, exec_code, id)
      values
        (v_id_menu, v_user, v_counter);
------
      execute immediate 'grant VBXL_USER to ' || v_user;
      dbms_output.put_line('User' || ' : ' || v_user || '     ' ||
                           'Password : bank12345');
      close c_check_position;
      close c_check_ora;
      commit;
    end if;
  
  end if;

  --excpetions
exception
  when e_position then
   raise_application_error(-20001,'Mocemuli Position ar arsebobs - '|| p_position );
   when e_ora then
    raise_application_error(-20001,'Mocemuli User ukve arsebobs - '|| p_ora_name );
  
end create_user;



-------


procedure update_role(p_ora_name varchar2,p_menu_id number) is 

cursor c_check_ora(p_ora varchar2) is
    select * from krn_user b where b.ora_name = p_ora;
cursor c_menu_id(p_id number) is
    select * from krn_menu b where b.id = p_id;

  v_check_ora  c_check_ora%rowtype;
  v_id_menu     c_menu_id%rowtype;
  v_menu_id     krn_menu_links.id_menu%type     :=p_menu_id;
  v_ora_name   krn_menu_links.exec_code%type  :=p_ora_name;
  v_counter       krn_menu_links.id%type;
  e_check_ora   exception;
  e_check_id     exception;

begin
  open c_check_ora(p_ora_name);
  fetch c_check_ora
    into v_check_ora;
  if c_check_ora%notfound then

    close c_check_ora;
    raise e_check_ora;

  else
    open c_menu_id(p_menu_id);
    fetch c_menu_id
      into v_id_menu;

    if c_menu_id%notfound then
      close c_menu_id;
      raise e_check_id;

    else
      select max(id) into v_counter from krn_menu_links;
      v_counter := v_counter + 1;
      insert into krn_menu_links
        (id_menu, exec_code, id)
      values
        (v_menu_id, v_ora_name, v_counter);
      commit;
      close c_check_ora;
      close c_menu_id;
    end if;

  end if;

exception
  when e_check_ora then
    raise_application_error(-20001,'Mocemuli User ar arsebobs - '|| p_ora_name );
  when e_check_id then
    raise_application_error(-20001,'Role ar arsebobs  - '|| p_menu_id );
  when others then
    raise_application_error(sqlcode, sqlerrm);
end;

--------

procedure give_other_users_roles(p_ora_name_to     varchar2,
                                                      p_ora_name_from varchar2) is
cursor c_check_ora(p_ora varchar2) is
    select * from krn_user b where b.ora_name = p_ora;
cursor c_check_ora2(p_ora varchar2) is
    select * from krn_user b where b.ora_name = p_ora;


  cursor c_menu_id is
    select id_menu from krn_menu_links where exec_code = p_ora_name_from;
  v_check_ora         c_check_ora%rowtype;
  v_check_ora2        c_check_ora%rowtype;
  v_menu_id            c_menu_id%rowtype;
  v_counter    number;
  v_ora_name krn_menu_links.exec_code%type := p_ora_name_to;
  e_no_data exception;
  e_no_data2 exception;
begin

  open c_check_ora(p_ora_name_to);
  fetch c_check_ora
    into v_check_ora;
  if c_check_ora%notfound then raise e_no_data; close c_check_ora;

 else 
 open c_check_ora2(p_ora_name_from);
  fetch c_check_ora
    into v_check_ora2;
 if c_check_ora2%notfound then raise e_no_data2; close c_check_ora;
 else 
  for v_menu_id in c_menu_id loop
    select max(id) into v_counter from krn_menu_links;
    v_counter := v_counter + 1;
    insert into krn_menu_links
      (id_menu, exec_code, id)
    values
      (v_menu_id.id_menu, v_ora_name, v_counter);
  end loop;
close c_check_ora;
end if;
end if;
exception
  when e_no_data then
    raise_application_error(-20001,'Mocemuli User ar arsebobs - '|| p_ora_name_to );
  when e_no_data2 then
    raise_application_error(-20001,'Mocemuli User ar arsebobs - '|| p_ora_name_from );
  when others then
    raise_application_error(sqlcode, sqlerrm);
end give_other_users_roles;

----------

procedure unlock_user(p_ora_name varchar2,
                                       p_lock        varchar2 default 'UNLOCK') is
  cursor c_check_ora(p_ora varchar2) is
    select * from krn_user b where b.ora_name = p_ora;
  v_check_ora c_check_ora%rowtype;
  v_ora_name  krn_user.ora_name%type := upper(p_ora_name);
  e_no_data exception;
begin
  open c_check_ora(p_ora_name);
  fetch c_check_ora
    into v_check_ora;
  if c_check_ora%notfound then
    raise e_no_data;
    close c_check_ora;
  else
    execute immediate 'alter user ' || v_ora_name || ' account ' || p_lock;
    close c_check_ora;
  end if;
exception
  when e_no_data then
    raise_application_error(-20001,'Mocemuli User ar arsebobs - ' || p_ora_name);
  when others then
    raise_application_error(sqlcode, sqlerrm);
end unlock_user;



----------
procedure change_user_password(p_ora_name varchar2, p_password varchar2) is
  cursor c_check_ora(p_ora varchar2) is
    select * from krn_user b where b.ora_name = p_ora;

  v_check_ora c_check_ora%rowtype;
  v_username krn_user.ora_name%type := upper(p_ora_name);
  e_no_data exception;

begin
  open c_check_ora(p_ora_name);
  fetch c_check_ora
    into v_check_ora;

  if c_check_ora%notfound then
    raise e_no_data;
    close c_check_ora;
  else
    execute immediate 'ALTER SESSION ENABLE COMMIT IN PROCEDURE';
    execute immediate 'ALTER USER "' || v_username || '" IDENTIFIED BY "' ||
                      p_password || '"';
    execute immediate 'ALTER SESSION DISABLE COMMIT IN PROCEDURE';
  end if;

exception
  when e_no_data then
    raise_application_error(-20001,'Mocemuli User ar arsebobs - ' || p_ora_name);
  when others then
    raise_application_error(sqlcode, sqlerrm);
end change_user_password;

-------

---------

procedure kill_seasion(p_username varchar2) is
  v_username gv$session.osuser%type      := lower(p_username);
  v_sid           gv$session.sid%type;
  v_serial        gv$session.serial#%type;
begin
  select a.sid
    into v_sid
    from gv$session a
   where a.schemaname = 'FORS'
     and a.osuser = v_username
      and a.P3TEXT is not null;
  select a.serial#
    into v_serial
    from gv$session a
   where a.schemaname = 'FORS'
     and a.osuser = v_username
     and a.P3TEXT is not null;
  execute immediate 'alter system kill session ''' || v_sid || ',' ||
                    v_serial || '''';
end kill_seasion;

---

procedure create_new_vabank_user(p_username varchar2, p_ora_name varchar2) is
  cursor c_ora_check(p_ora_name varchar2) is
    select a.ora_name from krn_user a where a.ora_name = p_ora_name;
  v_ora_check c_ora_check%rowtype;
  v_username      krn_user.ora_name%type := lower(p_username);
  v_ora_name     krn_user.ora_name%type := upper(p_ora_name);
  e_no_data exception;


begin

  open c_ora_check(p_ora_name);
  fetch c_ora_check
    into v_ora_check;
  if c_ora_check%found then

    insert into bpm_users
      (ora_user,domain_user,domain_name,photo_file_id,language,ui_skin,help_mode)
    values
      (v_ora_name, v_username, 'BOG0', 1, 'GE', 'Light', 'E');
    execute immediate 'ALTER USER "' || v_ora_name ||
                      '"GRANT CONNECT THROUGH BPM';
    close c_ora_check;
  else
    close c_ora_check;
    raise e_no_data;
  end if;

exception
  when e_no_data then
    raise_application_error(-20001, 'Mocemuli User ar arsebobs - ' || p_ora_name);
  when others then
    raise_application_error(sqlcode, sqlerrm);
end create_new_vabank_user;

--
procedure new_vabank_role(p_ora_name varchar2, p_role_name varchar2) is
  cursor c_role_name(p_role varchar2) is
    select * from bpm_roles a where a.role_name = p_role;

  cursor c_check_ora(p_ora varchar2) is
    select * from krn_user b where b.ora_name = p_ora;

  cursor c_is_defualt(p_name varchar2) is
    select a.id
      from bpm_user_roles a
     where a.user_name = p_name
      and a.is_default = 'Y';
  v_role c_role_name%rowtype;
  v_check_ora c_check_ora%rowtype;
  v_is_defualt c_is_defualt%rowtype;
  v_ora_name   bpm_user_roles.user_name%type := upper(p_ora_name);
  v_role_name  bpm_user_roles.role_name%type := upper(p_role_name);
  v_counter    bpm_user_roles.id%type;
  e_ora_name exception;
  e_role_name exception;
begin
open c_check_ora(p_ora_name);
fetch c_check_ora into v_check_ora;
  if c_check_ora%notfound then
    raise e_ora_name;
    close c_check_ora;
 else open c_role_name(p_role_name);
fetch c_role_name into v_role;
if c_role_name%notfound then raise e_role_name; close c_role_name;
 else 
  select max(a.id) into v_counter from bpm_user_roles a;
  v_counter := v_counter + 1;
    open c_is_defualt(v_ora_name);
    fetch c_is_defualt
      into v_is_defualt;
    if c_is_defualt%found then
      insert into bpm_user_roles
        (id, user_name, role_name, is_default)
      values
        (v_counter, v_ora_name, v_role_name, 'N');
      close c_is_defualt;
    elsif c_is_defualt%notfound then
      insert into bpm_user_roles
        (id, user_name, role_name, is_default)
      values
        (v_counter, v_ora_name, v_role_name, 'Y');
      close c_is_defualt;
    else
      close c_is_defualt;
    end if;
end if ;
end if;

exception 
  when e_role_name then
   raise_application_error(-20001,'Mocemuli Role_name ar arsebobs - '|| p_role_name );
   when e_ora_name then
    raise_application_error(-20001,'Mocemuli User ukve arsebobs - '|| p_ora_name );
    when others then raise_application_error(sqlcode,sqlerrm);
end new_vabank_role;
----


procedure update_position(p_ora_name krn_user.ora_name%type,
                          p_position krn_user.position%type) is
  cursor c_check_position(p_pos varchar2) is
    select * from krn_position a where a.pos_name = p_pos;

  cursor c_check_ora(p_ora varchar2) is
    select * from krn_user b where b.ora_name = p_ora;
  ---
  v_check_position c_check_position%rowtype;
  v_check_ora      c_check_ora%rowtype;
  e_ora      exception;
  e_position exception;
begin
  open c_check_ora(p_ora_name);
  fetch c_check_ora
    into v_check_ora;
  if c_check_ora%found then
    close c_check_ora;
    raise e_ora;
  elsif c_check_ora%notfound then
    open c_check_position(p_position);
    fetch c_check_position
      into v_check_position;
    if c_check_position%notfound then
      raise e_position;
      close c_check_position;
    else
      update krn_user a
         set a.position = p_position
       where a.ora_name = p_ora_name;
      close c_check_position;
      close c_check_ora;
    end if;
  end if;

exception
  when e_position then
    raise_application_error(-20001,
                            'Mocemuli Position ar arsebobs - ' ||
                            p_position);
  when e_ora then
    raise_application_error(-20001,
                            'Mocemuli User ukve arsebobs - ' || p_ora_name);
  when others then
    raise_application_error(sqlcode, sqlerrm);
  
end update_position;

procedure create_only_new_vabank(p_ora_name             krn_user.ora_name%type,
                                 p_username             bpm_users.domain_user%type,
                                 p_new_vabank_role_name bpm_roles.role_name%type) is

cursor c_check_username (p_user varchar2) is 
select*from bpm_users where domain_user=p_user;
v_check_username  c_check_username%rowtype;
e_check exception;

begin

open c_check_username(p_username);
fetch c_check_username into v_check_username;

if c_check_username%found then raise e_check; close c_check_username;
else 
  help_desk_pack.create_user(p_ora_name => p_ora_name);
  help_desk_pack.create_new_vabank_user(p_username => p_username,
                                                                            p_ora_name => p_ora_name);
  help_desk_pack.new_vabank_role(p_ora_name  => p_ora_name,
                                                               p_role_name => p_new_vabank_role_name);
  dbms_output.put_line('axali vabankis user aris : ' || p_username ||
                                        ' paroli rac windowszea gawerili, roli aris  ' ||
                                                                      p_new_vabank_role_name);
close c_check_username;
end if ;
exception 
 when e_check then 
    raise_application_error(-20001,
                            'Mocemuli User ukve arsebobs - ' || p_username);
 when others then
    raise_application_error(sqlcode, sqlerrm);
end create_only_new_vabank;



--

end help_desk_pack;
/
