import os

from time import time
import pandas as pd
from sqlalchemy import create_engine
from db_config import USER, PASSWORD, HOST, PORT, DB

def download_file(url_code, filename):
    if not os.path.exists(filename):
        os.system(f'gdown --id {url_code} --output {filename}')

    
if __name__ == '__main__':
    # Download csv files
    transaction_url_code ='1Zk3HXgutt29mcU7A0zGnUyaf8b1huGTR'
    csv_file = 'transactions.csv'
    print('='*30)
    print(f'Downloading {csv_file}')
    download_file(transaction_url_code, csv_file)

    # Ingest
    print('='*30)
    print(f'Ingesting {csv_file} to database')
    
    df_iter = pd.read_csv(csv_file, iterator=True, chunksize=100000)

    # Iterate
    df = next(df_iter)

    # Convert time
    df.purchase_date = pd.to_datetime(df.purchase_date)

    # Create engine to connect to pg db
    engine = create_engine(f'postgresql://{USER}:{PASSWORD}@{HOST}:{PORT}/{DB}')

    # Import data into database, first we get the columns names
    df.head(n=0).to_sql(name=csv_file[:-4], con=engine, if_exists='replace')

    # Import data
    df.to_sql(name=csv_file[:-4], con=engine, if_exists='append')

    # Import the rest
    while True:
        try:            
            t_start = time()

            df = next(df_iter)
            
            df.to_sql(name=csv_file[:-4], con=engine, if_exists='append')

            t_end = time()

            print('inserted another chunk, took %.3f second' % (t_end - t_start))
        except StopIteration:
            print("Finished ingesting data into the postgres database")
            break