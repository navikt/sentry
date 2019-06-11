from django.db import connection, transaction
## Fix on sentry issue...
## https://github.com/getsentry/sentry/issues/9270
try:
    cursor = connection.cursor()
    cursor.execute('''
        create or replace function sentry_increment_project_counter(project bigint, delta int) returns int as
        $$
        declare
            new_val int;
        begin
            loop
                update sentry_projectcounter set value = value + delta where project_id = project returning value into new_val;
                if found then return new_val; end if;
                begin
                    insert into sentry_projectcounter(project_id, value) values (project, delta) returning value into new_val;
                    return new_val;
                exception
                    when unique_violation then
                end;
            end loop;
        end
        $$ language plpgsql;
    ''')
    transaction.commit_unless_managed()
except:
    pass
