# -*- coding: utf-8 -*-
""" Normolize words from chat"""

import sys
import csv

import mysql.connector
import pymorphy2


CSV_FILENAME = 'c:\\temp\\output_pymorphy2.csv'
OPERATION_TYPE = 'write'

def main():
    """
    1.Processing argv`s
    2.Processing argv`s

    """
    if len(sys.argv) > 2:
        CSV_FILENAME = sys.argv[1] # arg1 - csv file name
        OPERATION_TYPE = sys.argv[2]      # arg2 - operation type: [write|read]
    else:
        print('arg1 - csv file name')
        print('arg2 - operation type: [write|read]')
        sys.exit(0)

    if OPERATION_TYPE not in ['write', 'read']:
        print('Unknown operation type: ' + OPERATION_TYPE)
        sys.exit(0)

    morph = pymorphy2.MorphAnalyzer()

# write to file
    if OPERATION_TYPE == 'write':
# connection config
        db_var = mysql.connector.connect(user='areon_user',
                                         password='nG4ez93fSU1t',
                                         host='192.168.3.138',
                                         database='AREONITR',
                                         charset='utf8', use_unicode=True)

        if db_var.is_connected():
            print("connected ok")
            cursor = db_var.cursor()
            sql = 'SELECT distinct c.atom FROM TMP_chat_atoms_clear c \
                   where c.chat_id= %s'
            try:
                cursor.execute(sql, [id])
                row = cursor.fetchone()
                csv_file = open(CSV_FILENAME, 'w')
                csv_writer = csv.writer(csv_file, delimiter='\t')

                while row is not None:
                    atom_var = row[0].lower()
                    lem = morph.parse(atom_var)[0].normal_form
                    csv_row = list(row)
                    csv_row.append(lem)
                    print(atom_var + '=>' + lem)
                    csv_writer.writerow(csv_row)
                    row = cursor.fetchone()
                csv_file.close()

            except AttributeError:
                print('Error')
        else:
            print('Not connected to database')
        db_var.close()

# read from file =============
    elif OPERATION_TYPE == 'read':
        print('read csv file...')
        csv_file = open(CSV_FILENAME, 'rb')
        csv_reader = csv.reader(csv_file, delimiter='\t')
        for row in csv_reader:
            print(row[0] + ':' + row[1])
        csv_file.close()

if __name__ == "__main__":
    main()
