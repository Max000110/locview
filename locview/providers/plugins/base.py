class ProviderPlugin:
    name = "base"

    def fetch(self, *args, **kwargs):
        raise NotImplementedError
