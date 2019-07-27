//  Copyright 2019 Bryant Luk
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

internal struct AnyCodingKey: CodingKey, Equatable {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    init<Key>(_ base: Key) where Key: CodingKey {
        if let intValue = base.intValue {
            self.init(intValue: intValue)!
        } else {
            self.init(stringValue: base.stringValue)!
        }
    }
}

extension AnyCodingKey: Comparable {
    static func < (lhs: AnyCodingKey, rhs: AnyCodingKey) -> Bool {
        return lhs.stringValue < rhs.stringValue
    }
}

extension AnyCodingKey: Hashable {
    func hash(into hasher: inout Hasher) {
        if let intValue = self.intValue {
            hasher.combine(intValue)
            return
        }
        hasher.combine(self.stringValue)
    }
}
