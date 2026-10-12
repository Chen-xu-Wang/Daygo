import assert from 'node:assert/strict'
import test from 'node:test'

import { MAX_PROVIDER_IMAGES, maxImagesError } from '../src/stores/providers'

// The per-request image cap mirrors Go's ai.MaxImages (5): 0 means the
// default, 1–5 lower it, anything else is rejected before the binding call.
test('provider image cap accepts 0 through the Go maximum and nothing else', () => {
  assert.equal(MAX_PROVIDER_IMAGES, 5)
  for (const value of [0, 1, 5]) assert.equal(maxImagesError(value), null, `value ${value}`)
  for (const value of [6, 10, 20, -1, 2.5, Number.NaN]) assert.equal(maxImagesError(value), 'range', `value ${value}`)
})
