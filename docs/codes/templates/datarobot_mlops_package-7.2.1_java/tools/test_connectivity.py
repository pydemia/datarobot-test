import argparse
import requests


class TestConnectivity(object):
    """
    Test connectivity to DataRobot MLOps.
    """

    AUTHORIZATION_TOKEN_PREFIX = "Token "
    API_VERSION = "api/v2/version/"
    RESPONSE_FULL_API_VERSION = "versionString"
    RESPONSE_API_MAJOR_VERSION = "major"
    RESPONSE_API_MINOR_VERSION = "minor"

    def __init__(self, service_url, api_key, verify=True):
        self._service_url = service_url
        self._api_key = self.AUTHORIZATION_TOKEN_PREFIX + api_key
        self._verify = verify
        self._common_headers = {"Authorization": self._api_key}
        self._api_version = None
        self._api_major_version = None
        self._api_minor_version = None

    def get_api_version(self):
        url = self._service_url + "/" + self.API_VERSION
        headers = dict(self._common_headers)
        try:
            response = requests.get(url, headers=headers, verify=self._verify)
            if response.ok:
                self._api_version = response.json()[self.RESPONSE_FULL_API_VERSION]
                self._api_major_version = response.json()[self.RESPONSE_API_MAJOR_VERSION]
                self._api_minor_version = response.json()[self.RESPONSE_API_MINOR_VERSION]
                print("Successfully connected to {}".format(self._service_url))
            else:
                print("Call to {} failed: {}".format(url, response.text))
        except requests.exceptions.ConnectionError as e:
            raise Exception(
                "Connection to DataRobot MLOps [{}] refused; {}".format(self._service_url, e))


def _parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--url", dest="url", required=True, help="MLOps Service URL")
    parser.add_argument("--token", dest="token", required=True, help="API token")
    parser.add_argument("--verify-ssl", dest="verify", required=False,
                        default=True, help="Verify SSL certificate")
    args = parser.parse_args()

    return args


def main():
    options = _parse_args()
    verify = True
    if options.verify == "False":
        verify = False
    tester = TestConnectivity(options.url, options.token, verify=verify)
    tester.get_api_version()


if __name__ == "__main__":
    main()
