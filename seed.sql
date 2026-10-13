-- Beispielstruktur. Nach schema.sql ausführen.
insert into departments (name) values ('Fertigung'), ('Abfüllung'), ('Logistik'), ('Verwaltung');

insert into rooms (department_id, name)
select id, r from departments d
cross join lateral (values ('Halle 1'), ('Halle 2')) v(r)
where d.name in ('Fertigung','Abfüllung');

insert into rooms (department_id, name)
select id, 'Lagerhalle' from departments where name = 'Logistik';
insert into rooms (department_id, name)
select id, r from departments d cross join lateral (values ('Küche'), ('Büro Nord')) v(r)
where d.name = 'Verwaltung';

insert into machines (room_id, name, manufacturer, cycle, last_maintenance, spare_parts)
select r.id, m.name, m.herst, m.zyk::cycle_kind, current_date - (m.tage || ' days')::interval, m.teile
from rooms r
join departments d on d.id = r.department_id
join (values
  ('Spritzgussmaschine SG-1','Arburg','monatlich', 40, array['Heizband 230V','Dichtsatz Schnecke']),
  ('CNC-Fräse 01','DMG Mori','quartalsweise', 20, array['Kühlmittelpumpe','Spindellager'])
) as m(name,herst,zyk,tage,teile) on true
where d.name = 'Fertigung' and r.name = 'Halle 1';

insert into machine_checklists (machine_id, label, position)
select m.id, v.l, v.p from machines m
join (values ('Sichtprüfung auf Leckagen',0),('Schmierstellen abschmieren',1),
             ('Filter prüfen und tauschen',2),('Not-Halt geprüft',3),('Probelauf durchgeführt',4)) v(l,p) on true;

-- Beispiel-Formblatt: Messmittelliste QM / FB Technik (vierteljährlich)
-- Spalten: Messmittel, Nr., Standort, Toleranz, Messbereich, Einheit (Stammdaten) + IST-Wert, Vergleichswert (Techniker)
insert into protocol_templates (name, form_no, room_id, cycle, tolerance_key, columns_def, rows_def)
select 'Messmittelliste', 'QM / FB Technik', r.id, 'quartalsweise', 'c4',
  '[{"key":"c1","label":"Messmittel","kind":"stamm"},
    {"key":"c2","label":"Nr.","kind":"stamm"},
    {"key":"c3","label":"Standort","kind":"stamm"},
    {"key":"c4","label":"Toleranz","kind":"stamm"},
    {"key":"c5","label":"Messbereich","kind":"stamm"},
    {"key":"c6","label":"Einheit","kind":"stamm"},
    {"key":"c7","label":"IST-Wert","kind":"ist"},
    {"key":"c8","label":"Vergleichswert","kind":"vergleich"}]'::jsonb,
  '[{"id":"r1","werte":{"c1":"Messschieber digital","c2":"MM-001","c3":"Werkstatt","c4":"±0,02","c5":"0–150","c6":"mm"}},
    {"id":"r2","werte":{"c1":"Bügelmessschraube","c2":"MM-002","c3":"Werkstatt","c4":"±0,01","c5":"0–25","c6":"mm"}},
    {"id":"r3","werte":{"c1":"Drehmomentschlüssel","c2":"MM-014","c3":"Montage","c4":"±4 %","c5":"20–100","c6":"Nm"}},
    {"id":"r4","werte":{"c1":"Waage Wareneingang","c2":"MM-021","c3":"Lager","c4":"+0,5 / -0,5","c5":"0–60","c6":"kg"}},
    {"id":"r5","werte":{"c1":"Manometer Kompressor","c2":"MM-030","c3":"Technikraum","c4":"±0,1","c5":"0–16","c6":"bar"}}]'::jsonb
from rooms r join departments d on d.id = r.department_id
where d.name = 'Fertigung' and r.name = 'Halle 1'
  and not exists (select 1 from protocol_templates where name = 'Messmittelliste')
limit 1;
