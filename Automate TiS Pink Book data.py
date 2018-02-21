# -*- coding: utf-8 -*-
"""
Automate TiS Pink Book Data

    @author: Tino Hamadziripi
"""

import os
import pandas as pd 

filepath = "W:\Trade Asymmetries\Resources"        #insert filepath
filename = "TiS geogs updated with Pink Book 2017 data.xlsx"
os.chdir(filepath)

mapping = pd.read_excel(filename, sheetname = "BPM6 Mapping", index_col = None)
raw_table = pd.read_excel(filename, sheetname = "TiS", index_col = None)
countries = pd.read_excel(filename, sheetname = "country descriptions", index_col = None)

countries["Table Header"] = countries["Table Header"].str.lower()
mydict = dict(zip(countries["Table Header"],countries["Code"]))
country = input("Insert country in lowercase: ")
country = mydict[country]

table = raw_table[raw_table["Country"].astype("str") == country]

table.iloc[:,1] = table.iloc[:,1].astype("str")
table.iloc[:,1] = table.iloc[:,1].map(lambda x: x.lstrip(x[:6]))
table.iloc[:,1] = table.iloc[:,1].map(lambda x: x.lstrip('B'))
table.iloc[:,1] = table.iloc[:,1].map(lambda x: x.lstrip(x[:1]))
table.drop(table.columns[3:18], axis = 1, inplace = True)

map_df = [pd.DataFrame(mapping[1]), pd.DataFrame(mapping[2]), pd.DataFrame(mapping[3])]

sector = pd.concat(map_df, axis = 1, ignore_index = True)
sector.fillna(method = 'bfill', axis = 1, inplace = True)
sector_n = sector[0]
sector_n.dropna(inplace = True )
sector_n.reset_index(drop = True, inplace = True)

dic = {}
for i, v in sector_n.iteritems():
    keys = sector_n[i].strip()
    values = sector_n[i].split()[0]
    values = values.strip(':')
    if values.endswith('.'):        values = values.strip('.')
    dic[keys] = values
    

df1 = pd.DataFrame(sector_n)
df1.columns = ['Exports']
df2 = pd.DataFrame(sector_n)
df2.columns = ['Imports']

df1['Transaction'] = df1.iloc[:,0].map(dic)
df2['Transaction'] = df2.iloc[:,0].map(dic)

matched = table[table['Transaction'].isin(df1['Transaction'])]
matched2 = table[table['Transaction'].isin(df2['Transaction'])]

exp = matched[matched['Direction'] == 'EX']
exports = df1.merge(exp, how = 'inner', on = ['Transaction'])

imp = matched2[matched2['Direction'] == 'IM']
imports = df2.merge(imp, how = 'inner', on = ['Transaction'])

new_file = ' TiS Pink Book 2017 data.xlsx'
writer = pd.ExcelWriter(country + new_file, engine = 'xlsxwriter')

exports.to_excel(writer, sheet_name = 'Exports', index = False)
imports.to_excel(writer, sheet_name = 'Imports', index = False)
raw_table.to_excel(writer, sheet_name = 'raw table', index = False)
mapping.to_excel(writer, sheet_name = 'BPM6 mapping', index = False)
countries.to_excel(writer, sheet_name = 'country description', index = False)
writer.save()
os.startfile(filepath+'\\'+ country+ new_file)