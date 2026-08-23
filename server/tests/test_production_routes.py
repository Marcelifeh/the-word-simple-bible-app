import os
import unittest

os.environ["ENVIRONMENT"] = "production"

from app.main import app  # noqa: E402


class ProductionRouteTests(unittest.TestCase):
    def test_debug_info_is_not_registered_in_production(self):
        paths = {route.path for route in app.routes}
        self.assertNotIn("/debug/info", paths)


if __name__ == "__main__":
    unittest.main()
