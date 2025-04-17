import pandas as pd

file_path = '/Users/yanisamira/Downloads/data/transfers.csv'
output_file = '/Users/yanisamira/Downloads/data/transfers_cleaned.csv'

columns_to_keep = [
    "player_id", "transfer_date", "transfer_season", "from_club_id", "to_club_id", "transfer_fee", "market_value_in_eur"
]

df = pd.read_csv(file_path, usecols=columns_to_keep)

df_cleaned = df[df['transfer_fee'].notnull()]

df_cleaned.to_csv(output_file, index=False)

print(f"Fichier nettoyé généré : {output_file}")
