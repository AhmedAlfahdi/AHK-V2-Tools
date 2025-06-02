import sys
import json
try:
    import urllib.request
    from_cur, to_cur, amount = sys.argv[1], sys.argv[2], float(sys.argv[3])

    crypto_currencies = ['BTC', 'ETH', 'USDT', 'BNB', 'XRP', 'ADA', 'SOL', 'DOT', 'DOGE', 'AVAX', 'MATIC', 'LINK', 'UNI', 'LTC', 'BCH', 'XLM', 'VET', 'ETC', 'FIL', 'TRX']
    crypto_id_map = {'BTC': 'bitcoin', 'ETH': 'ethereum', 'USDT': 'tether', 'BNB': 'binancecoin', 'XRP': 'ripple', 'ADA': 'cardano', 'SOL': 'solana', 'DOT': 'polkadot', 'DOGE': 'dogecoin', 'AVAX': 'avalanche-2', 'MATIC': 'matic-network', 'LINK': 'chainlink', 'UNI': 'uniswap', 'LTC': 'litecoin', 'BCH': 'bitcoin-cash', 'XLM': 'stellar', 'VET': 'vechain', 'ETC': 'ethereum-classic', 'FIL': 'filecoin', 'TRX': 'tron'}

    with open(sys.argv[4], 'w', encoding='utf-8') as output:
        if from_cur in crypto_currencies:
            crypto_id = crypto_id_map.get(from_cur, from_cur.lower())
            if to_cur in crypto_currencies:
                to_crypto_id = crypto_id_map.get(to_cur, to_cur.lower())
                url = f'https://api.coingecko.com/api/v3/simple/price?ids={crypto_id},{to_crypto_id}&vs_currencies=usd'
                with urllib.request.urlopen(url, timeout=5) as response:
                    data = json.loads(response.read().decode())
                from_rate = data[crypto_id]['usd']
                to_rate = data[to_crypto_id]['usd']
                rate = from_rate / to_rate
            else:
                vs_currency = to_cur.lower()
                url = f'https://api.coingecko.com/api/v3/simple/price?ids={crypto_id}&vs_currencies={vs_currency}'
                with urllib.request.urlopen(url, timeout=5) as response:
                    data = json.loads(response.read().decode())
                rate = data[crypto_id][vs_currency]
        elif to_cur in crypto_currencies:
            crypto_id = crypto_id_map.get(to_cur, to_cur.lower())
            vs_currency = from_cur.lower()
            url = f'https://api.coingecko.com/api/v3/simple/price?ids={crypto_id}&vs_currencies={vs_currency}'
            with urllib.request.urlopen(url, timeout=5) as response:
                data = json.loads(response.read().decode())
            rate = 1 / data[crypto_id][vs_currency]
        else:
            url = f'https://api.exchangerate-api.com/v4/latest/{from_cur}'
            with urllib.request.urlopen(url, timeout=5) as response:
                data = json.loads(response.read().decode())
            rate = data['rates'].get(to_cur)

        if rate is not None:
            result = amount * rate
            output.write(f'{amount} {from_cur} = {result:.4f} {to_cur}\n')
            output.write(f'Rate: 1 {from_cur} = {rate:.6f} {to_cur}\n')
except Exception as e:
    with open(sys.argv[4], 'w', encoding='utf-8') as output:
        output.write(f'Error: {e}\n')