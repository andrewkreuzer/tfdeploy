def lambda_handler(event=None, context=None):
    return event.get("URL", "No Url")
